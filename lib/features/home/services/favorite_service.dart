import 'package:flutter/foundation.dart';
import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/core/services/wishlist_notifier.dart';
import 'package:proplinq/features/home/models/property_model.dart';

class FavoriteService {
  final ApiService _apiService = ApiService();

  /// Get all favorite properties
  Future<List<PropertyModel>> getFavorites() async {
    try {
      final response = await _apiService.get(
        ApiConstants.getFavourites,
        requiresAuth: true,
      );

      if (response.success && response.data != null) {
        final raw = response.data!['data'] ?? response.data;
        if (raw is List) {
          return raw
              .whereType<Map>()
              .map((json) {
                try {
                  return PropertyModel.fromJson(Map<String, dynamic>.from(json));
                } catch (_) {
                  return null;
                }
              })
              .whereType<PropertyModel>()
              .toList();
        }
      }

      return [];
    } catch (e) {
      return [];
    }
  }

  /// Add property to favorites — returns error message on failure, null on success
  Future<String?> addToFavorites(int propertyId) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.addFavourite}/$propertyId',
        requiresAuth: true,
      );
      debugPrint('❤️ [FavoriteService] add $propertyId → success=${response.success} status=${response.statusCode} msg=${response.message}');
      if (response.success) {
        WishlistNotifier().notify();
        return null;
      }
      return response.message ?? 'Failed to add to favourites';
    } catch (e) {
      debugPrint('❤️ [FavoriteService] add error: $e');
      return e.toString();
    }
  }

  /// Remove property from favorites — returns error message on failure, null on success
  Future<String?> removeFromFavorites(int propertyId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.deleteFavourite}/$propertyId',
        requiresAuth: true,
      );
      debugPrint('❤️ [FavoriteService] remove $propertyId → success=${response.success} status=${response.statusCode} msg=${response.message}');
      if (response.success) {
        WishlistNotifier().notify();
        return null;
      }
      return response.message ?? 'Failed to remove from favourites';
    } catch (e) {
      debugPrint('❤️ [FavoriteService] remove error: $e');
      return e.toString();
    }
  }

  /// Toggle favorite status — returns error message on failure, null on success
  Future<String?> toggleFavorite(int propertyId, bool isCurrentlyFavorite) async {
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(propertyId);
    } else {
      return await addToFavorites(propertyId);
    }
  }
}
