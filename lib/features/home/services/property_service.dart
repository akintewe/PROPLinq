import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/property_model.dart';
import 'dart:io';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

class PropertyService {
  static final PropertyService _instance = PropertyService._internal();
  factory PropertyService() => _instance;
  PropertyService._internal();

  final ApiService _apiService = ApiService();

  /// Create a new property with form data
  Future<ApiResponse<Map<String, dynamic>>> createProperty({
    required String type,
    required String title,
    required String description,
    required String price,
    required String category,
    required String location,
    required String bedrooms,
    required String bathrooms,
    required String gated,
    required String parking,
    required List<String> features,
    required List<File> images,
    List<File>? images360,
    File? video,
  }) async {
    try {

      // Prepare form fields
      final Map<String, String> fields = {
        'type': type.toLowerCase(),
        'title': title,
        'description': description,
        'price': price.replaceAll(RegExp(r'[^\d]'), ''), // Remove non-digits and currency symbols
        'category': _mapCategoryToApi(category),
        'location': location,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'gated': gated.toLowerCase() == 'yes' ? '1' : '0', // Send as 1/0 instead of true/false
        'parking': parking.toLowerCase() == 'yes' ? '1' : '0', // Send as 1/0 instead of true/false
      };

      // Add features as indexed fields
      for (int i = 0; i < features.length; i++) {
        fields['features[$i]'] = features[i];
      }

      // Prepare files with validation and resizing
      final Map<String, File> files = {};
      
      // Add regular images
      for (int i = 0; i < images.length; i++) {
        final validatedImage = await _validateAndResizeImage(images[i]);
        if (validatedImage != null) {
          files['images[$i]'] = validatedImage;
        } else {
        }
      }
      
      // Add 360 images
      if (images360 != null && images360.isNotEmpty) {
        for (int i = 0; i < images360.length; i++) {
          final validatedImage = await _validateAndResizeImage(images360[i]);
          if (validatedImage != null) {
            files['360[$i]'] = validatedImage;
          } else {
          }
        }
      }
      
      // Add video
      if (video != null) {
        files['video'] = video;
      }

      if (files.isEmpty) {
        return ApiResponse.error(
          message: 'No valid files to upload',
          statusCode: 400,
        );
      }


      final response = await _apiService.postFormData<Map<String, dynamic>>(
        ApiConstants.createProperty,
        fields: fields,
        files: files,
        requiresAuth: true,
        fromJson: (json) => json,
      );


      if (response.success && response.data != null) {
        
        // Clean up temporary files
        await _cleanupTempFiles(files.values.toList());
        
        return response;
      } else {
        if (response.errors != null) {
        }
        
        // Clean up temporary files even on error
        await _cleanupTempFiles(files.values.toList());
        
        return response;
      }
    } catch (e) {
      return ApiResponse.error(
        message: 'Error creating property: $e',
        statusCode: 0,
      );
    }
  }

  /// Clean up temporary files
  Future<void> _cleanupTempFiles(List<File> tempFiles) async {
    for (final file in tempFiles) {
      try {
        if (file.path.contains('resized_') && await file.exists()) {
          await file.delete();
        }
      } catch (e) {
      }
    }
  }

  /// Map UI category to API category format
  String _mapCategoryToApi(String uiCategory) {
    switch (uiCategory.toLowerCase()) {
      case 'for rent':
        return 'for_rent';
      case 'for sale':
        return 'for_sale';
      case 'hotel':
        return 'hotel';
      case 'shortlet':
        return 'shortlet';
      default:
        return 'for_rent';
    }
  }

  /// Validate and resize image to meet API requirements
  Future<File?> _validateAndResizeImage(File imageFile) async {
    try {
      // Read the image file
      final Uint8List bytes = await imageFile.readAsBytes();
      final img.Image? originalImage = img.decodeImage(bytes);
      
      if (originalImage == null) {
        return null;
      }


      // Try different standard sizes that most APIs accept
      final List<Map<String, int>> standardSizes = [
        {'width': 800, 'height': 600},   // Standard 4:3
        {'width': 1200, 'height': 800},  // Standard 3:2
        {'width': 1024, 'height': 768},  // Common size
        {'width': 1600, 'height': 1200}, // High quality
        {'width': 1920, 'height': 1080}, // Full HD
      ];

      for (final size in standardSizes) {
        try {
          final resizedImage = img.copyResize(
            originalImage,
            width: size['width']!,
            height: size['height']!,
          );
          
          
          // Convert to PNG (better for APIs)
          final Uint8List resizedBytes = img.encodePng(resizedImage);
          
          // Create temporary file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(resizedBytes);
          
          
          return tempFile;
        } catch (e) {
          continue;
        }
      }
      
      
      // Fallback: try to use original image if it's reasonable
      if (originalImage.width >= 300 && originalImage.height >= 300 && 
          originalImage.width <= 4096 && originalImage.height <= 4096) {
        try {
          final Uint8List originalBytes = img.encodePng(originalImage);
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/original_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(originalBytes);
          
          return tempFile;
        } catch (e) {
        }
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Fetch all properties with pagination support
  Future<List<PropertyModel>> fetchProperties({
    String? type,
    String? location,
    String? priceMin,
    String? priceMax,
    String? category,
  }) async {
    try {
      
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (location != null) queryParams['location'] = location;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;
      if (category != null) queryParams['category'] = category;


      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.listProperties,
        queryParams: queryParams,
        requiresAuth: true,
        fromJson: (json) => json,
      );


      if (response.success && response.data != null) {
        final data = response.data!;
        final List<dynamic> propertiesData = data['data'] as List<dynamic>;
        
        
        final List<PropertyModel> properties = propertiesData
            .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
            .toList();

        return properties;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  /// Fetch all properties from all pages (handles pagination)
  Future<List<PropertyModel>> fetchAllProperties({
    String? type,
    String? location,
    String? priceMin,
    String? priceMax,
    String? category,
  }) async {
    try {
      
      List<PropertyModel> allProperties = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        
        // Build query parameters including page
        final Map<String, String> queryParams = {'page': currentPage.toString()};
        if (type != null) queryParams['type'] = type;
        if (location != null) queryParams['location'] = location;
        if (priceMin != null) queryParams['price_min'] = priceMin;
        if (priceMax != null) queryParams['price_max'] = priceMax;
        if (category != null) queryParams['category'] = category;

        final response = await _apiService.get<Map<String, dynamic>>(
          ApiConstants.listProperties,
          queryParams: queryParams,
          requiresAuth: true,
          fromJson: (json) => json,
        );

        if (response.success && response.data != null) {
          final data = response.data!;
          final List<dynamic> propertiesData = data['data'] as List<dynamic>;
          final int currentPageFromResponse = data['current_page'] as int;
          final int lastPage = data['last_page'] as int;
          
          
          // Debug: Check if API data includes images
          if (propertiesData.isNotEmpty) {
            final firstProperty = propertiesData.first as Map<String, dynamic>;
          }
          
          final List<PropertyModel> pageProperties = propertiesData
              .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
              .toList();

          allProperties.addAll(pageProperties);
          
          // Check if there are more pages
          hasMorePages = currentPageFromResponse < lastPage;
          currentPage = currentPageFromResponse + 1;
        } else {
          hasMorePages = false;
        }
      }

      return allProperties;
    } catch (e) {
      return [];
    }
  }

  /// Fetch property details by ID using the dedicated endpoint
  Future<PropertyModel?> fetchPropertyDetails(int propertyId) async {
    try {
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.properties}/$propertyId',
        requiresAuth: true,
        fromJson: (json) => json,
      );


      if (response.success && response.data != null) {
        final data = response.data!;
        
        // Check if the response has a 'data' wrapper or is direct
        Map<String, dynamic> propertyData;
        if (data.containsKey('data')) {
          propertyData = data['data'] as Map<String, dynamic>;
        } else {
          propertyData = data;
        }
        
        final property = PropertyModel.fromJson(propertyData);
        return property;
      } else {
        if (response.errors != null && response.errors!.isNotEmpty) {
        }
        return null;
      }
    } catch (e, stackTrace) {
      return null;
    }
  }

  /// Fetch agent's own properties
  Future<List<PropertyModel>> fetchMyProperties() async {
    try {
      
      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.myProperties,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      
      if (response.errors != null && response.errors!.isNotEmpty) {
      }

      if (response.success && response.data != null) {
        final data = response.data!;
        
        // Check if data has the expected structure
        if (data.containsKey('data')) {
          final List<dynamic> propertiesData = data['data'] as List<dynamic>;
          
          if (propertiesData.isNotEmpty) {
          }
          
          final List<PropertyModel> properties = propertiesData
              .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
              .toList();

          
          if (properties.isNotEmpty) {
            for (int i = 0; i < properties.length && i < 3; i++) {
              final prop = properties[i];
            }
            if (properties.length > 3) {
            }
          }
          
          return properties;
        } else {
          return [];
        }
      } else {
        if (response.statusCode != null) {
        }
        return [];
      }
    } catch (e, stackTrace) {
      return [];
    }
  }

  /// Update an existing property
  Future<bool> updateProperty({
    required int propertyId,
    required String title,
    required String description,
    required String price,
    required String location,
    required int bedrooms,
    required int bathrooms,
    required bool gated,
    required bool parking,
    required List<String> features,
    required String status,
  }) async {
    try {

      // Prepare request body
      final Map<String, dynamic> body = {
        'title': title,
        'description': description,
        'price': double.tryParse(price.replaceAll(RegExp(r'[^\d.]'), '')) ?? 0.0,
        'location': location,
        'bedrooms': bedrooms,
        'bathrooms': bathrooms,
        'gated': gated,
        'parking': parking,
        'features': features,
        'status': status,
      };


      final response = await _apiService.put(
        '/properties/$propertyId',
        body: body,
        requiresAuth: true,
      );

      
      if (response.statusCode == 200 || response.statusCode == 204) {
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      return false;
    }
  }

  /// Delete a property
  Future<bool> deleteProperty(int propertyId) async {
    try {

      final response = await _apiService.delete(
        '/properties/$propertyId',
        requiresAuth: true,
      );

      
      if (response.success) {
        return true;
      } else {
        return false;
      }
    } catch (e, stackTrace) {
      return false;
    }
  }
} 