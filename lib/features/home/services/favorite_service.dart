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

  /// Add property to favorites
  Future<bool> addToFavorites(int propertyId) async {
    try {
      final response = await _apiService.post(
        '${ApiConstants.addFavourite}/$propertyId',
        requiresAuth: true,
      );
      if (response.success) WishlistNotifier().notify();
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Remove property from favorites
  Future<bool> removeFromFavorites(int propertyId) async {
    try {
      final response = await _apiService.delete(
        '${ApiConstants.deleteFavourite}/$propertyId',
        requiresAuth: true,
      );
      if (response.success) WishlistNotifier().notify();
      return response.success;
    } catch (e) {
      return false;
    }
  }

  /// Toggle favorite status
  Future<bool> toggleFavorite(int propertyId, bool isCurrentlyFavorite) async {
    if (isCurrentlyFavorite) {
      return await removeFromFavorites(propertyId);
    } else {
      return await addToFavorites(propertyId);
    }
  }
}
