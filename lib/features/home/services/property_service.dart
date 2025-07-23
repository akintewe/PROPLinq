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
  Future<Map<String, dynamic>?> createProperty({
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
  }) async {
    try {
      print('🏠 Creating property...');
      print('📋 Property Data:');
      print('Type: $type');
      print('Title: $title');
      print('Category: $category');
      print('Location: $location');
      print('Price: $price');
      print('Features: $features');
      print('Images: ${images.length} files');

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
      for (int i = 0; i < images.length; i++) {
        final validatedImage = await _validateAndResizeImage(images[i]);
        if (validatedImage != null) {
          files['images[$i]'] = validatedImage;
        } else {
          print('❌ Skipping invalid image: ${images[i].path}');
        }
      }

      if (files.isEmpty) {
        print('❌ No valid images to upload');
        return null;
      }

      print('📤 Sending request to API...');
      print('Fields: $fields');
      print('Files: ${files.keys}');

      final response = await _apiService.postFormData<Map<String, dynamic>>(
        ApiConstants.createProperty,
        fields: fields,
        files: files,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      print('📋 Create Property API Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');

      if (response.success && response.data != null) {
        print('✅ Property created successfully');
        print('📊 Response Data: ${response.data}');
        
        // Clean up temporary files
        await _cleanupTempFiles(files.values.toList());
        
        return response.data;
      } else {
        print('❌ Failed to create property: ${response.message}');
        if (response.errors != null) {
          print('❌ Errors: ${response.errors}');
        }
        
        // Clean up temporary files even on error
        await _cleanupTempFiles(files.values.toList());
        
        return null;
      }
    } catch (e) {
      print('❌ Error creating property: $e');
      return null;
    }
  }

  /// Clean up temporary files
  Future<void> _cleanupTempFiles(List<File> tempFiles) async {
    for (final file in tempFiles) {
      try {
        if (file.path.contains('resized_') && await file.exists()) {
          await file.delete();
          print('🗑️ Cleaned up temp file: ${file.path}');
        }
      } catch (e) {
        print('⚠️ Failed to cleanup temp file: ${file.path}, error: $e');
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
        print('❌ Failed to decode image: ${imageFile.path}');
        return null;
      }

      print('📏 Original image dimensions: ${originalImage.width}x${originalImage.height}');

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
          
          print('🔄 Trying size: ${resizedImage.width}x${resizedImage.height}');
          
          // Convert to PNG (better for APIs)
          final Uint8List resizedBytes = img.encodePng(resizedImage);
          
          // Create temporary file
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/resized_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(resizedBytes);
          
          print('✅ Image resized to: ${resizedImage.width}x${resizedImage.height}');
          print('✅ Image saved as: ${tempFile.path}');
          
          return tempFile;
        } catch (e) {
          print('❌ Failed to resize to ${size['width']}x${size['height']}: $e');
          continue;
        }
      }
      
      print('❌ Failed to resize image to any standard size');
      
      // Fallback: try to use original image if it's reasonable
      if (originalImage.width >= 300 && originalImage.height >= 300 && 
          originalImage.width <= 4096 && originalImage.height <= 4096) {
        try {
          final Uint8List originalBytes = img.encodePng(originalImage);
          final tempDir = Directory.systemTemp;
          final tempFile = File('${tempDir.path}/original_${DateTime.now().millisecondsSinceEpoch}.png');
          await tempFile.writeAsBytes(originalBytes);
          
          print('✅ Using original image as fallback: ${originalImage.width}x${originalImage.height}');
          return tempFile;
        } catch (e) {
          print('❌ Failed to save original image: $e');
        }
      }
      
      return null;
    } catch (e) {
      print('❌ Error processing image: $e');
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
      print('🏠 Fetching properties from API...');
      
      // Build query parameters
      final Map<String, String> queryParams = {};
      if (type != null) queryParams['type'] = type;
      if (location != null) queryParams['location'] = location;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;
      if (category != null) queryParams['category'] = category;

      print('📋 Query Parameters: $queryParams');

      final response = await _apiService.get<Map<String, dynamic>>(
        ApiConstants.listProperties,
        queryParams: queryParams,
        fromJson: (json) => json,
      );

      print('📋 Properties API Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');

      if (response.success && response.data != null) {
        final data = response.data!;
        final List<dynamic> propertiesData = data['data'] as List<dynamic>;
        
        print('📊 Found ${propertiesData.length} properties');
        
        final List<PropertyModel> properties = propertiesData
            .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
            .toList();

        print('✅ Successfully parsed ${properties.length} properties');
        return properties;
      } else {
        print('❌ Failed to fetch properties: ${response.message}');
        return [];
      }
    } catch (e) {
      print('❌ Error fetching properties: $e');
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
      print('🔄 Fetching all properties with pagination...');
      
      List<PropertyModel> allProperties = [];
      int currentPage = 1;
      bool hasMorePages = true;

      while (hasMorePages) {
        print('📄 Fetching page $currentPage...');
        
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
          fromJson: (json) => json,
        );

        if (response.success && response.data != null) {
          final data = response.data!;
          final List<dynamic> propertiesData = data['data'] as List<dynamic>;
          final int currentPageFromResponse = data['current_page'] as int;
          final int lastPage = data['last_page'] as int;
          
          print('📊 Page $currentPageFromResponse: Found ${propertiesData.length} properties');
          
          final List<PropertyModel> pageProperties = propertiesData
              .map((json) => PropertyModel.fromJson(json as Map<String, dynamic>))
              .toList();

          allProperties.addAll(pageProperties);
          
          // Check if there are more pages
          hasMorePages = currentPageFromResponse < lastPage;
          currentPage = currentPageFromResponse + 1;
        } else {
          print('❌ Failed to fetch page $currentPage: ${response.message}');
          hasMorePages = false;
        }
      }

      print('✅ Successfully fetched ${allProperties.length} properties from all pages');
      return allProperties;
    } catch (e) {
      print('❌ Error fetching all properties: $e');
      return [];
    }
  }

  /// Fetch property details by ID
  Future<PropertyModel?> fetchPropertyDetails(int propertyId) async {
    try {
      print('🏠 Fetching property details for ID: $propertyId...');
      
      final response = await _apiService.get<Map<String, dynamic>>(
        '${ApiConstants.listProperties}/$propertyId',
        fromJson: (json) => json,
      );

      print('📋 Property Details API Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');

      if (response.success && response.data != null) {
        final data = response.data!;
        print('📊 Property Details Data:');
        print(data);
        
        final property = PropertyModel.fromJson(data);
        print('✅ Successfully parsed property details');
        return property;
      } else {
        print('❌ Failed to fetch property details: ${response.message}');
        return null;
      }
    } catch (e) {
      print('❌ Error fetching property details: $e');
      return null;
    }
  }
} 