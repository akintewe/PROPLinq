import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/storage_service.dart';

class RecentlyViewedService {
  static const String _prefsKeyPrefix = 'recently_viewed_properties_';
  static const int _expirationHours = 24;

  /// Returns a user-scoped prefs key so different accounts never share data.
  Future<String> _key() async {
    final userData = await StorageService().getUserData();
    final userId = userData?['id']?.toString();
    if (userId == null || userId.isEmpty) return '${_prefsKeyPrefix}guest';
    return '$_prefsKeyPrefix$userId';
  }

  /// Add a property to recently viewed (only for non-owners)
  Future<void> addToRecentlyViewed(Map<String, dynamic> propertyData,
      {bool isOwner = false}) async {
    if (isOwner) return;
    try {
      final key = await _key();
      final prefs = await SharedPreferences.getInstance();

      final existingJson = prefs.getString(key);
      List<Map<String, dynamic>> recentlyViewed = [];

      if (existingJson != null) {
        final decoded = json.decode(existingJson);
        if (decoded is List) {
          recentlyViewed = decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList();
        }
      }

      final propertyId = propertyData['id']?.toString();
      if (propertyId == null || propertyId.isEmpty) return;

      recentlyViewed.removeWhere(
          (p) => p['id']?.toString() == propertyId);

      final now = DateTime.now().toIso8601String();
      recentlyViewed.insert(0, {...propertyData, 'viewed_at': now});

      final cutoffTime =
          DateTime.now().subtract(Duration(hours: _expirationHours));
      recentlyViewed.removeWhere((p) {
        final viewedAt = DateTime.tryParse(p['viewed_at'] as String? ?? '');
        return viewedAt == null || viewedAt.isBefore(cutoffTime);
      });

      await prefs.setString(key, json.encode(recentlyViewed));
    } catch (_) {}
  }

  /// Get all recently viewed properties for the current user.
  Future<List<Map<String, dynamic>>> getRecentlyViewed() async {
    try {
      final key = await _key();
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return [];

      final decoded = json.decode(jsonString);
      final all = decoded is List
          ? decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      final cutoffTime =
          DateTime.now().subtract(Duration(hours: _expirationHours));
      final valid = all.where((p) {
        final viewedAt = DateTime.tryParse(p['viewed_at'] as String? ?? '');
        return viewedAt != null && viewedAt.isAfter(cutoffTime);
      }).toList();

      if (valid.length != all.length) {
        await prefs.setString(key, json.encode(valid));
      }
      return valid;
    } catch (_) {
      return [];
    }
  }

  /// Remove a specific property from the current user's recently viewed.
  Future<void> removeFromRecentlyViewed(int propertyId) async {
    try {
      final key = await _key();
      final prefs = await SharedPreferences.getInstance();
      final jsonString = prefs.getString(key);
      if (jsonString == null) return;

      final decoded = json.decode(jsonString);
      final all = decoded is List
          ? decoded
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];

      all.removeWhere((p) => p['id']?.toString() == propertyId.toString());
      await prefs.setString(key, json.encode(all));
    } catch (_) {}
  }

  /// Clear recently viewed for the current user.
  Future<void> clearAll() async {
    try {
      final key = await _key();
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } catch (_) {}
  }

  Future<int> getCount() async {
    final properties = await getRecentlyViewed();
    return properties.length;
  }
}
