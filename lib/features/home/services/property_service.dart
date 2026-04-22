import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../models/property_model.dart';
import '../models/paginated_properties_response.dart';
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

  /// Fetch properties with pagination support (returns single page)
  Future<PaginatedPropertiesResponse> fetchPropertiesPaginated({
    int page = 1,
    String? type,
    String? location,
    String? priceMin,
    String? priceMax,
    String? category,
  }) async {
    try {
      print('📡 [PropertyService] Fetching properties (paginated) - Page $page');

      // Build query parameters
      final Map<String, String> queryParams = {'page': page.toString()};
      if (type != null) queryParams['type'] = type;
      if (location != null) queryParams['location'] = location;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get<dynamic>(
        ApiConstants.listProperties,
        queryParams: queryParams,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      print('   - Response success: ${response.success}');
      print('   - Response data type: ${response.data?.runtimeType}');

      if (response.success && response.data != null) {
        final data = response.data!;

        print('📦 [PropertyService] RAW RESPONSE DATA:');
        print(data);
        print('📦 [PropertyService] ========================================');

        // Handle pagination structure
        if (data is Map<String, dynamic>) {
          print('   - Response is a Map');
          print('   - Contains "data" key: ${data.containsKey('data')}');
          print('   - Contains "current_page" key: ${data.containsKey('current_page')}');
          print('   - Contains "last_page" key: ${data.containsKey('last_page')}');
          print('   - Contains "total" key: ${data.containsKey('total')}');

          if (data.containsKey('data')) {
            print('   - data["data"] type: ${data['data']?.runtimeType}');
            if (data['data'] is List) {
              print('   - data["data"] length: ${(data['data'] as List).length}');
            }
          }

          // Check if it has pagination structure
          if (data.containsKey('data') && data['data'] is List) {
            print('   - Paginated response: ${data['current_page']}/${data['last_page']}');
            final paginatedResponse = PaginatedPropertiesResponse.fromJson(data);
            print('✅ [PropertyService] Fetched ${paginatedResponse.properties.length} properties on page $page');
            return paginatedResponse;
          }
        }

        // Fallback: treat as non-paginated data
        print('   - Non-paginated response, treating as single page');
        final rawData = data is List ? data : (data is Map && data.containsKey('data') ? data['data'] : null);
        final propertiesData = rawData is List ? rawData : <dynamic>[];
        return PaginatedPropertiesResponse(
          properties: propertiesData,
          currentPage: 1,
          lastPage: 1,
          total: propertiesData.length,
          perPage: propertiesData.length,
          hasMorePages: false,
        );
      } else {
        print('❌ [PropertyService] Failed to fetch properties: ${response.message}');
        return PaginatedPropertiesResponse(
          properties: [],
          currentPage: page,
          lastPage: page,
          total: 0,
          perPage: 0,
          hasMorePages: false,
        );
      }
    } catch (e) {
      print('❌ [PropertyService] Error fetching paginated properties: $e');
      return PaginatedPropertiesResponse(
        properties: [],
        currentPage: page,
        lastPage: page,
        total: 0,
        perPage: 0,
        hasMorePages: false,
      );
    }
  }

  /// Fetch properties without auth token — for guest users (same logic as authenticated version)
  Future<PaginatedPropertiesResponse> fetchPropertiesPaginatedPublic({
    int page = 1,
    String? type,
    String? location,
    String? priceMin,
    String? priceMax,
    String? category,
  }) async {
    try {
      final Map<String, String> queryParams = {'page': page.toString()};
      if (type != null) queryParams['type'] = type;
      if (location != null) queryParams['location'] = location;
      if (priceMin != null) queryParams['price_min'] = priceMin;
      if (priceMax != null) queryParams['price_max'] = priceMax;
      if (category != null) queryParams['category'] = category;

      final response = await _apiService.get<dynamic>(
        ApiConstants.listPropertiesPublic,
        queryParams: queryParams,
        requiresAuth: false,
        fromJson: (json) => json,
      );

      if (response.success && response.data != null) {
        final data = response.data!;

        if (data is Map<String, dynamic>) {
          // Standard paginated response: { data: [...], current_page, last_page, ... }
          if (data.containsKey('data') && data['data'] is List) {
            final paginatedResponse = PaginatedPropertiesResponse.fromJson(data);
            return paginatedResponse;
          }

          // Nested: { data: { data: [...], current_page, ... } }
          if (data.containsKey('data') && data['data'] is Map<String, dynamic>) {
            final inner = data['data'] as Map<String, dynamic>;
            if (inner.containsKey('data') && inner['data'] is List) {
              return PaginatedPropertiesResponse.fromJson(inner);
            }
          }
        }

        // Fallback: plain list
        final rawData = data is List ? data : (data is Map && data.containsKey('data') ? data['data'] : null);
        final propertiesData = rawData is List ? rawData : <dynamic>[];
        return PaginatedPropertiesResponse(
          properties: propertiesData,
          currentPage: 1,
          lastPage: 1,
          total: propertiesData.length,
          perPage: propertiesData.length,
          hasMorePages: false,
        );
      }

      return PaginatedPropertiesResponse(
        properties: [], currentPage: page, lastPage: page, total: 0, perPage: 0, hasMorePages: false,
      );
    } catch (e) {
      return PaginatedPropertiesResponse(
        properties: [], currentPage: page, lastPage: page, total: 0, perPage: 0, hasMorePages: false,
      );
    }
  }

  /// Fetch promoted/featured properties without auth — for guest users
  Future<List<PropertyModel>> fetchPromotedPropertiesPublic() async {
    try {
      final response = await _apiService.get<dynamic>(
        ApiConstants.promotedPropertiesPublic,
        requiresAuth: false,
        fromJson: (json) => json,
      );
      if (response.success && response.data != null) {
        final data = response.data!;
        List<dynamic> items = [];
        if (data is List) {
          items = data;
        } else if (data is Map<String, dynamic>) {
          if (data['data'] is List) items = data['data'] as List;
        }
        return items
            .whereType<Map>()
            .map((j) {
              try { return PropertyModel.fromJson(Map<String, dynamic>.from(j)); } catch (_) { return null; }
            })
            .whereType<PropertyModel>()
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  /// Fetch all properties with pagination support (DEPRECATED - use fetchPropertiesPaginated)
  @Deprecated('Use fetchPropertiesPaginated for better performance')
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


      final response = await _apiService.get<dynamic>(
        ApiConstants.listProperties,
        queryParams: queryParams,
        requiresAuth: true,
        fromJson: (json) {
          // Handle both Map and the data structure
          if (json is Map<String, dynamic> && json.containsKey('data')) {
            return json['data']; // Return the data array/list directly
          }
          return json;
        },
      );


      if (response.success && response.data != null) {
        final data = response.data!;

        // Handle new structure: data can be a direct array or nested
        List<dynamic> propertiesData;
        if (data is List) {
          // Data is directly an array
          propertiesData = data;
        } else if (data is Map<String, dynamic>) {
          // Check if data contains a 'data' key with array
          if (data['data'] is List) {
            propertiesData = data['data'] as List<dynamic>;
          } else {
            propertiesData = [];
          }
        } else {
          propertiesData = [];
        }

        final List<PropertyModel> properties = propertiesData
            .whereType<Map>()
            .map((json) {
              try { return PropertyModel.fromJson(Map<String, dynamic>.from(json)); }
              catch (_) { return null; }
            })
            .whereType<PropertyModel>()
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

        final response = await _apiService.get<dynamic>(
          ApiConstants.listProperties,
          queryParams: queryParams,
          requiresAuth: true,
          fromJson: (json) {
            // The API service passes jsonData['data'] to fromJson when it's a Map
            // or the whole jsonData when it's a List
            // So we just return it as-is to handle both cases
            return json;
          },
        );

        print('📡 [PropertyService] Fetch all properties - Page $currentPage');
        print('   - Response success: ${response.success}');
        print('   - Response status code: ${response.statusCode}');
        print('   - Response message: ${response.message}');
        print('   - Response data type: ${response.data?.runtimeType}');

        if (response.success && response.data != null) {
          final data = response.data!;
          
          print('   - Data type: ${data.runtimeType}');
          if (data is Map) {
            print('   - Data keys: ${(data as Map).keys.toList()}');
          }
          
          // Handle new structure: data can be a direct array or nested with pagination
          List<dynamic> propertiesData;
          int? currentPageFromResponse;
          int? lastPage;
          
          if (data is List) {
            // Data is directly an array (no pagination)
            print('   - Data is List with ${data.length} items');
            propertiesData = data;
            hasMorePages = false; // No pagination if direct array
          } else if (data is Map<String, dynamic>) {
            // Check if data contains a 'data' key with array (paginated)
            if (data.containsKey('data') && data['data'] is List) {
              propertiesData = data['data'] as List<dynamic>;
              final rawCp = data['current_page'];
              final rawLp = data['last_page'];
              currentPageFromResponse = rawCp is int ? rawCp : int.tryParse(rawCp?.toString() ?? '');
              lastPage = rawLp is int ? rawLp : int.tryParse(rawLp?.toString() ?? '');
              
              print('   - Found nested data array with ${propertiesData.length} items');
              print('   - Current page: $currentPageFromResponse, Last page: $lastPage');
              
              // Check if there are more pages
              if (currentPageFromResponse != null && lastPage != null) {
                hasMorePages = currentPageFromResponse < lastPage;
              } else {
                hasMorePages = false; // No pagination info, assume last page
              }
            } else {
              // Fallback: empty array
              print('   - No data array found in response');
              propertiesData = [];
              hasMorePages = false;
            }
          } else {
            print('   - Unknown data type: ${data.runtimeType}');
            propertiesData = [];
            hasMorePages = false;
          }
          
          final List<PropertyModel> pageProperties = propertiesData
              .whereType<Map>()
              .map((json) {
                try { return PropertyModel.fromJson(Map<String, dynamic>.from(json)); }
                catch (_) { return null; }
              })
              .whereType<PropertyModel>()
              .toList();

          print('📦 [PropertyService] Page $currentPage: Parsed ${pageProperties.length} properties');
          print('📦 [PropertyService] Featured count: ${pageProperties.where((p) => p.isFeatured).length}');
          print('📦 [PropertyService] Non-featured count: ${pageProperties.where((p) => !p.isFeatured).length}');

          allProperties.addAll(pageProperties);
          
          // Update page for next iteration
          if (hasMorePages && currentPageFromResponse != null) {
            currentPage = currentPageFromResponse + 1;
          }
        } else {
          hasMorePages = false;
        }
      }

      print('✅ [PropertyService] Total properties fetched: ${allProperties.length}');
      print('✅ [PropertyService] Total featured: ${allProperties.where((p) => p.isFeatured).length}');
      print('✅ [PropertyService] Total non-featured: ${allProperties.where((p) => !p.isFeatured).length}');
      
      return allProperties;
    } catch (e) {
      print('❌ [PropertyService] Error in fetchAllProperties: $e');
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
        final inner = data['data'];
        if (inner is Map) {
          propertyData = Map<String, dynamic>.from(inner);
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
  /// Fetch promoted properties
  Future<List<PropertyModel>> fetchPromotedProperties() async {
    try {
      print('🔵 [PropertyService] Fetching promoted properties...');
      print('🔵 [PropertyService] Endpoint: ${ApiConstants.promotedProperties}');
      
      final response = await _apiService.get<dynamic>(
        ApiConstants.promotedProperties,
        requiresAuth: true,
        fromJson: (json) => json,
      );

      print('🔵 [PropertyService] Response received:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Message: ${response.message}');
      print('   - Data type: ${response.data?.runtimeType}');
      print('   - Data is null: ${response.data == null}');
      
      // Handle 404 - no promoted properties found (this is expected if none exist)
      if (response.statusCode == 404) {
        print('ℹ️ [PropertyService] No promoted properties found (404) - this is normal if none exist');
        print('🔵🔵🔵 [PropertyService] ========================================');
        return [];
      }

      if (response.success && response.data != null) {
        final data = response.data!;
        print('🔵 [PropertyService] Processing response data...');
        print('   - Data type: ${data.runtimeType}');
        
        if (data is Map<String, dynamic>) {
          print('   - Data is Map with keys: ${data.keys.toList()}');
        } else if (data is List) {
          print('   - Data is List with ${data.length} items');
        }
        
        // Handle different response structures
        List<dynamic> propertiesData = [];
        if (data is Map<String, dynamic>) {
          if (data.containsKey('data')) {
            print('   - Found "data" key in Map');
            if (data['data'] is List) {
              propertiesData = data['data'] as List<dynamic>;
              print('   - Extracted ${propertiesData.length} properties from data.data (List)');
            } else if (data['data'] is Map) {
              final inner = data['data'] as Map;
              if (inner.containsKey('data') && inner['data'] is List) {
                propertiesData = inner['data'] as List<dynamic>;
                print('   - Extracted ${propertiesData.length} properties from nested data.data');
              }
            }
          } else {
            print('   - Map does not contain "data" key');
          }
        } else if (data is List) {
          propertiesData = data;
          print('   - Using data directly as List (${propertiesData.length} items)');
        }

        if (propertiesData.isNotEmpty) {
          print('   - First property structure: ${propertiesData[0]}');
        }

        final properties = propertiesData
            .whereType<Map>()
            .map((item) {
              try { return PropertyModel.fromJson(Map<String, dynamic>.from(item)); }
              catch (_) { return null; }
            })
            .whereType<PropertyModel>()
            .toList();

        print('✅ [PropertyService] Successfully parsed ${properties.length} promoted properties');
        print('🔵🔵🔵 [PropertyService] ========================================');
        
        return properties;
      } else {
        if (response.statusCode == 404) {
          print('ℹ️ [PropertyService] No promoted properties found (404) - returning empty list');
        } else {
          print('❌ [PropertyService] Failed to fetch promoted properties');
          print('   - Success: ${response.success}');
          print('   - Status Code: ${response.statusCode}');
          print('   - Message: ${response.message}');
        }
        print('🔵🔵🔵 [PropertyService] ========================================');
      }
      
      return [];
    } catch (e, stackTrace) {
      print('❌ [PropertyService] Error fetching promoted properties: $e');
      print('❌ [PropertyService] Stack trace: $stackTrace');
      print('🔵🔵🔵 [PropertyService] ========================================');
      return [];
    }
  }

  /// Promote a property
  Future<ApiResponse<Map<String, dynamic>>> promoteProperty(int propertyId) async {
    try {
      print('🔵 [PropertyService] Promoting property ID: $propertyId');
      print('🔵 [PropertyService] Endpoint: ${ApiConstants.promoteProperty(propertyId)}');
      
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.promoteProperty(propertyId),
        body: {
          'is_promoted': true,
        },
        requiresAuth: true,
        fromJson: (json) => json,
      );

      print('🔵 [PropertyService] Promote property response:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Message: ${response.message}');
      print('   - Data: ${response.data}');

      return response;
    } catch (e) {
      print('❌ [PropertyService] Error promoting property: $e');
      return ApiResponse.error(
        message: 'Error promoting property: $e',
        statusCode: 0,
      );
    }
  }

  Future<List<PropertyModel>> fetchMyProperties() async {
    try {
      print('🔵 [PropertyService] Fetching agent properties...');
      print('🔵 [PropertyService] Endpoint: ${ApiConstants.myProperties}');
      
      final response = await _apiService.get<dynamic>(
        ApiConstants.myProperties,
        requiresAuth: true,
        fromJson: (json) {
          // Return json as-is to handle both nested and direct structures
          return json;
        },
      );

      print('🔵 [PropertyService] Agent properties response:');
      print('   - Success: ${response.success}');
      print('   - Status Code: ${response.statusCode}');
      print('   - Message: ${response.message}');
      print('   - Data type: ${response.data?.runtimeType}');
      
      if (response.errors != null && response.errors!.isNotEmpty) {
        print('   - Errors: ${response.errors}');
      }

      if (response.success && response.data != null) {
        final data = response.data!;
        
        print('   - Data type: ${data.runtimeType}');
        if (data is Map) {
          print('   - Data keys: ${(data as Map).keys.toList()}');
        }
        
        // Handle new structure: data can be a direct array or nested with pagination
        List<dynamic> propertiesData;
        
        if (data is List) {
          // Data is directly an array
          print('   - Data is List with ${data.length} items');
          propertiesData = data;
        } else if (data is Map<String, dynamic>) {
          // Check if data contains a 'data' key with array (paginated)
          if (data.containsKey('data') && data['data'] is List) {
            propertiesData = data['data'] as List<dynamic>;
            print('   - Found nested data array with ${propertiesData.length} items');
            if (data.containsKey('current_page')) {
              print('   - Current page: ${data['current_page']}, Last page: ${data['last_page']}');
            }
          } else {
            print('   - No data array found in response');
            propertiesData = [];
          }
        } else {
          print('   - Unknown data type: ${data.runtimeType}');
          propertiesData = [];
        }
        
        final List<PropertyModel> properties = propertiesData
            .whereType<Map>()
            .map((json) {
              try { return PropertyModel.fromJson(Map<String, dynamic>.from(json)); }
              catch (_) { return null; }
            })
            .whereType<PropertyModel>()
            .toList();

        print('✅ [PropertyService] Successfully parsed ${properties.length} agent properties');
        print('🔵🔵🔵 [PropertyService] ========================================');
        
        return properties;
      } else {
        print('❌ [PropertyService] Failed to fetch agent properties');
        print('   - Success: ${response.success}');
        print('   - Status Code: ${response.statusCode}');
        print('   - Message: ${response.message}');
        return [];
      }
    } catch (e, stackTrace) {
      print('❌ [PropertyService] Error fetching agent properties: $e');
      print('   - Stack trace: $stackTrace');
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

  /// Rate a property
  Future<ApiResponse<Map<String, dynamic>>> rateProperty({
    required int propertyId,
    required int rating,
    required String comment,
  }) async {
    try {
      final response = await _apiService.post<Map<String, dynamic>>(
        ApiConstants.rateProperty(propertyId),
        body: {
          'rating': rating,
          'comment': comment,
        },
        requiresAuth: true,
        fromJson: (json) => json,
      );

      return response;
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to rate property: $e',
        statusCode: 0,
      );
    }
  }

  /// Search properties using the API natural language search endpoint
  /// GET /api/v1/properties/search?q=...&type=...&location=...
  Future<ApiResponse<List<PropertyModel>>> searchProperties({
    required String query,
    String? type,
    String? location,
    int? bedrooms,
    double? priceMin,
    double? priceMax,
    int page = 1,
  }) async {
    try {
      final params = <String, String>{};
      if (query.trim().isNotEmpty) params['q'] = query.trim();
      if (type != null && type.isNotEmpty) params['type'] = type;
      if (location != null && location.isNotEmpty) params['location'] = location;
      if (bedrooms != null) params['bedrooms'] = bedrooms.toString();
      if (priceMin != null) params['price_min'] = priceMin.toString();
      if (priceMax != null) params['price_max'] = priceMax.toString();
      params['page'] = page.toString();

      final response = await _apiService.get<List<PropertyModel>>(
        ApiConstants.searchProperties,
        queryParams: params,
        requiresAuth: false,
        fromJson: (json) {
          final nested = json['data'];
          final raw = (nested is Map ? nested['data'] : null) ?? nested ?? json;
          final dataList = raw is List ? raw : <dynamic>[];
          return dataList
              .whereType<Map>()
              .map((item) {
                try {
                  return PropertyModel.fromJson(Map<String, dynamic>.from(item));
                } catch (_) {
                  return null;
                }
              })
              .whereType<PropertyModel>()
              .toList();
        },
      );
      return response;
    } catch (e) {
      return ApiResponse.error(message: 'Search failed: $e', statusCode: 0);
    }
  }
} 