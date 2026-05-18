import 'package:flutter/material.dart';
import 'package:proplinq/features/home/services/property_service.dart';
import 'package:proplinq/features/home/models/property_model.dart';
import 'package:proplinq/features/home/views/property_details_view.dart';

/// Router for handling deep link navigation
class DeepLinkRouter {
  static final DeepLinkRouter _instance = DeepLinkRouter._internal();
  factory DeepLinkRouter() => _instance;
  DeepLinkRouter._internal();

  final PropertyService _propertyService = PropertyService();
  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  /// Navigate to property details from deep link
  Future<void> navigateToProperty({
    required BuildContext? context,
    required String propertyId,
    String? propertyType,
  }) async {
    try {
      
      if (propertyId.isEmpty) {
        _showError(context, 'Invalid property ID');
        return;
      }

      // Show loading indicator
      BuildContext? loadingContext = context;
      if (loadingContext != null && loadingContext.mounted) {
        showDialog(
          context: loadingContext,
          barrierDismissible: false,
          builder: (context) => const Center(
            child: CircularProgressIndicator(),
          ),
        );
      }

      // Fetch property details from API.
      // Deep link URLs use integer IDs (e.g. /property/shortlet/10).
      // Try direct fetch first; if that fails and the ID is a plain integer,
      // search the property list to find the matching UUID then fetch by UUID.
      PropertyModel? propertyModel;
      try {
        propertyModel = await _propertyService.fetchPropertyDetails(propertyId);
      } catch (e) {
        propertyModel = null;
      }

      if (propertyModel == null && int.tryParse(propertyId) != null) {
        try {
          propertyModel = await _propertyService.fetchPropertyByIntegerId(
            int.parse(propertyId),
            type: propertyType,
          );
        } catch (_) {}
      }

      // Dismiss loading indicator
      if (loadingContext != null && loadingContext.mounted) {
        try {
          Navigator.of(loadingContext, rootNavigator: true).pop();
        } catch (e) {
        }
      }

      if (propertyModel == null) {
        
        // Show error message with helpful info
        final navContext = context ?? navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          // Show error but don't block navigation
          ScaffoldMessenger.of(navContext).showSnackBar(
            SnackBar(
              content: Text('Property ID $propertyId not found. Please check the property ID or try again.'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 5),
              action: SnackBarAction(
                label: 'OK',
                textColor: Colors.white,
                onPressed: () {},
              ),
            ),
          );
        }
        return;
      }
      

      // Convert PropertyModel to Map for PropertyDetailsView
      final propertyData = _propertyModelToMap(propertyModel);

      // Navigate to property details - use root navigator to ensure it works from any screen
      final navContext = context ?? navigatorKey.currentContext;
      if (navContext != null && navContext.mounted) {
        try {
          // Use rootNavigator and pushReplacement if we're coming from deep link
          // This ensures we can navigate even if there's no valid context on current screen
          Navigator.of(navContext, rootNavigator: true).push(
            MaterialPageRoute(
              builder: (context) => PropertyDetailsView(
                propertyData: propertyData,
                isHomeSeeker: true, // Default to home seeker view
              ),
            ),
          );
        } catch (e, stackTrace) {
          // Try with regular navigator as fallback
          try {
            Navigator.of(navContext).push(
              MaterialPageRoute(
                builder: (context) => PropertyDetailsView(
                  propertyData: propertyData,
                  isHomeSeeker: true,
                ),
              ),
            );
          } catch (e2) {
            _showError(context, 'Failed to open property. Please try again.');
          }
        }
      } else {
        // Try to use navigatorKey directly
        if (navigatorKey.currentContext != null && navigatorKey.currentContext!.mounted) {
          try {
            Navigator.of(navigatorKey.currentContext!, rootNavigator: true).push(
              MaterialPageRoute(
                builder: (context) => PropertyDetailsView(
                  propertyData: propertyData,
                  isHomeSeeker: true,
                ),
              ),
            );
          } catch (e) {
            _showError(context, 'Failed to open property. Please try again.');
          }
        } else {
          _showError(context, 'Unable to navigate. Please restart the app.');
        }
      }
    } catch (e, stackTrace) {
      
      // Dismiss loading indicator if still showing
      if (context != null && context.mounted) {
        try {
          Navigator.of(context, rootNavigator: true).pop();
        } catch (popError) {
        }
      }
      
      // Show detailed error
      final errorMessage = 'Failed to load property: ${e.toString()}';
      _showError(context, errorMessage);
    }
  }

  /// Convert PropertyModel to Map format expected by PropertyDetailsView
  Map<String, dynamic> _propertyModelToMap(PropertyModel property) {
    // Convert images list to expected format
    List<Map<String, dynamic>>? imagesList;
    if (property.images != null && property.images!.isNotEmpty) {
      imagesList = property.images!.map((img) {
        return {
          'id': img['id'],
          'property_id': property.id,
          'full_url': img['full_url'] ?? img['image_url'] ?? property.imageUrl,
          'is_featured': img['is_featured'] ?? false,
        };
      }).toList();
    } else if (property.imageUrl != null) {
      // Fallback to single image
      imagesList = [
        {
          'id': property.id,
          'property_id': property.id,
          'full_url': property.imageUrl,
          'is_featured': true,
        }
      ];
    }

    // Convert user data
    Map<String, dynamic>? userMap;
    if (property.user != null) {
      userMap = {
        'id': property.user!.id,
        'full_name': property.user!.fullName,
        'email': property.user!.email,
        'phone_number': property.user!.phoneNumber,
        'location': property.user!.location,
        'agency_name': property.user!.agencyName,
        'agent_type': property.user!.agentType,
        'whatsapp_number': property.user!.whatsappNumber,
        'profile_image_full_url': property.user!.profileImageFullUrl,
        'kyc': property.user!.kyc != null
            ? {
                'user_id': property.user!.kyc!.userId,
                'status': property.user!.kyc!.status,
                'utility_bill_full_url': property.user!.kyc!.utilityBillFullUrl,
                'bank_statement_full_url': property.user!.kyc!.bankStatementFullUrl,
                'cac_document_full_url': property.user!.kyc!.cacDocumentFullUrl,
              }
            : null,
      };
    }

    return {
      'id': property.id,
      'user_id': property.userId,
      'type': property.type,
      'title': property.title,
      'description': property.description,
      'price': property.price,
      'category': property.category,
      'location': property.location,
      'image_url': property.imageUrl,
      'images': imagesList,
      'property360_images': property.property360Images,
      'video_url': property.videoUrl,
      'bedrooms': property.bedrooms,
      'bathrooms': property.bathrooms,
      'area': property.area,
      'features': property.features,
      'isLiked': property.isFavorite,
      'rating': '(5.0)', // Default rating - PropertyModel doesn't have rating field yet
      'user': userMap,
      'badges': property.user != null && property.user!.isVerified
          ? ['Verified Agent']
          : ['Unverified'],
    };
  }

  /// Show error message
  void _showError(BuildContext? context, String message) {
    final navContext = context ?? navigatorKey.currentContext;
    if (navContext != null && navContext.mounted) {
      ScaffoldMessenger.of(navContext).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  /// Handle deep link data and navigate accordingly
  Future<void> handleDeepLink(
    BuildContext? context,
    Map<String, dynamic> deepLinkData,
  ) async {
    try {
      final propertyId = deepLinkData['propertyId']?.toString();
      if (propertyId == null || propertyId.isEmpty) {
        return;
      }

      final propertyType = deepLinkData['propertyType']?.toString();
      

      await navigateToProperty(
        context: context,
        propertyId: propertyId,
        propertyType: propertyType,
      );
    } catch (e) {
    }
  }
}

