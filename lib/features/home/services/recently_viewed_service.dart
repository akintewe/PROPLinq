import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class RecentlyViewedService {
  static const String _prefsKey = 'recently_viewed_properties';
  static const int _expirationHours = 24;

  /// Add a property to recently viewed
  Future<void> addToRecentlyViewed(Map<String, dynamic> propertyData) async {
    try {
      print('👁️ [RecentlyViewedService] Adding property to recently viewed');
      print('👁️ [RecentlyViewedService] Property data: ${propertyData['id']}, title: ${propertyData['title']}');
      
      final prefs = await SharedPreferences.getInstance();
      
      // Get existing recently viewed properties
      final existingJson = prefs.getString(_prefsKey);
      List<Map<String, dynamic>> recentlyViewed = [];
      
      if (existingJson != null) {
        final decoded = json.decode(existingJson);
        if (decoded is List) {
          recentlyViewed = decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
        }
        print('👁️ [RecentlyViewedService] Found ${recentlyViewed.length} existing recently viewed properties');
      } else {
        print('👁️ [RecentlyViewedService] No existing recently viewed properties');
      }
      
      // Extract property ID - handle both int and string
      final idValue = propertyData['id'];
      String? propertyId;
      if (idValue != null) {
        if (idValue is int) {
          propertyId = idValue.toString();
        } else if (idValue is String) {
          propertyId = idValue;
        } else {
          propertyId = idValue.toString();
        }
      }
      
      if (propertyId == null || propertyId.isEmpty) {
        print('⚠️ [RecentlyViewedService] Property has no valid ID, cannot add');
        return;
      }
      
      print('👁️ [RecentlyViewedService] Property ID: $propertyId');
      
      // Remove existing entry with same ID (if any) to update position
      final beforeCount = recentlyViewed.length;
      recentlyViewed.removeWhere((p) {
        final pId = p['id'];
        final pIdStr = pId is int ? pId.toString() : (pId is String ? pId : pId?.toString());
        return pIdStr == propertyId;
      });
      final removed = beforeCount != recentlyViewed.length;
      if (removed) {
        print('👁️ [RecentlyViewedService] Removed existing entry for property $propertyId');
      }
      
      // Add property with current timestamp
      final now = DateTime.now().toIso8601String();
      recentlyViewed.insert(0, {
        ...propertyData,
        'viewed_at': now,
      });
      print('👁️ [RecentlyViewedService] Added property at position 0 with timestamp: $now');
      
      // Remove expired properties (older than 24 hours)
      final cutoffTime = DateTime.now().subtract(Duration(hours: _expirationHours));
      final beforeExpiredCount = recentlyViewed.length;
      recentlyViewed.removeWhere((p) {
        final viewedAtStr = p['viewed_at'] as String?;
        if (viewedAtStr == null) return true; // Remove if no timestamp
        final viewedAt = DateTime.tryParse(viewedAtStr);
        if (viewedAt == null) return true; // Remove if invalid timestamp
        return viewedAt.isBefore(cutoffTime); // Remove if older than 24 hours
      });
      final expiredCount = beforeExpiredCount - recentlyViewed.length;
      if (expiredCount > 0) {
        print('👁️ [RecentlyViewedService] Removed $expiredCount expired properties');
      }
      
      // Save back to preferences
      final updatedJson = json.encode(recentlyViewed);
      await prefs.setString(_prefsKey, updatedJson);
      print('✅ [RecentlyViewedService] Successfully saved ${recentlyViewed.length} recently viewed properties');
    } catch (e, stackTrace) {
      print('❌ [RecentlyViewedService] Error adding to recently viewed: $e');
      print('❌ [RecentlyViewedService] Stack trace: $stackTrace');
    }
  }

  /// Get all recently viewed properties (non-expired)
  Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      
      if (jsonString == null) return [];
      
      final decoded = json.decode(jsonString);
      final recentlyViewed = decoded is List
          ? decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];

      // Filter out expired properties (older than 24 hours)
      final cutoffTime = DateTime.now().subtract(Duration(hours: _expirationHours));
      final validProperties = recentlyViewed.where((p) {
        final viewedAtStr = p['viewed_at'] as String?;
        if (viewedAtStr == null) return false;
        final viewedAt = DateTime.tryParse(viewedAtStr);
        if (viewedAt == null) return false;
        return viewedAt.isAfter(cutoffTime);
      }).toList();
      
      // Clean up expired properties from storage
      if (validProperties.length != recentlyViewed.length) {
        final updatedJson = json.encode(validProperties);
        await prefs.setString(_prefsKey, updatedJson);
      }
      
      return validProperties;
    } catch (e) {
      return [];
    }
  }

  /// Remove a property from recently viewed
  Future<void> removeFromRecentlyViewed(int propertyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(_prefsKey);
      
      if (jsonString == null) return;
      
      final decoded = json.decode(jsonString);
      final recentlyViewed = decoded is List
          ? decoded.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList()
          : <Map<String, dynamic>>[];
      
      // Remove property with matching ID
      recentlyViewed.removeWhere((p) => p['id']?.toString() == propertyId.toString());
      
      // Save back
      final updatedJson = json.encode(recentlyViewed);
      await prefs.setString(_prefsKey, updatedJson);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Clear all recently viewed properties
  Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefsKey);
    } catch (e) {
      // Silently handle errors
    }
  }

  /// Get count of recently viewed properties
  Future<int> getCount() async {
    final properties = await getRecentlyViewed();
    return properties.length;
  }
}

