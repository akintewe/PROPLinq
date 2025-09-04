import 'package:proplinq/core/constants/api_constants.dart';
import 'package:proplinq/core/services/api_service.dart';
import 'package:proplinq/features/home/models/property_model.dart';

class FavoriteService {
  final ApiService _apiService = ApiService();

  /// Get all favorite properties
  Future<List<PropertyModel>> getFavorites() async {
    try {
      print('🔄 Fetching favorites from API...');
      final response = await _apiService.get(
        ApiConstants.getFavourites,
        requiresAuth: true,
      );
      
      print('📋 Favorites API Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      print('📊 Raw Data: ${response.data}');
      
      if (response.success && response.data != null) {
        final data = response.data!['data'] as List<dynamic>;
        print('🎯 Found ${data.length} favorite properties');
        
        final properties = data.map((json) {
          print('🏠 Processing property: ${json['title']} (ID: ${json['id']})');
          return PropertyModel.fromJson(json);
        }).toList();
        
        print('✅ Successfully parsed ${properties.length} favorite properties');
        return properties;
      }
      
      print('❌ No favorites found or API call failed');
      return [];
    } catch (e) {
      print('❌ Error fetching favorites: $e');
      return [];
    }
  }

  /// Add property to favorites
  Future<bool> addToFavorites(int propertyId) async {
    try {
      print('🔄 Adding property $propertyId to favorites...');
      
      final response = await _apiService.post(
        '${ApiConstants.addFavourite}/$propertyId',
        requiresAuth: true,
      );
      
      print('📋 Add to Favorites Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      
      return response.success;
    } catch (e) {
      print('❌ Error adding to favorites: $e');
      return false;
    }
  }

  /// Remove property from favorites
  Future<bool> removeFromFavorites(int propertyId) async {
    try {
      print('🔄 Removing property $propertyId from favorites...');
      
      final response = await _apiService.delete(
        '${ApiConstants.deleteFavourite}/$propertyId',
        requiresAuth: true,
      );
      
      print('📋 Remove from Favorites Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      
      return response.success;
    } catch (e) {
      print('❌ Error removing from favorites: $e');
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
