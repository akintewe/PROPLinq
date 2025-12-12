import 'dart:async';
import 'dart:io';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:uni_links/uni_links.dart';

/// Service to handle deep linking and deferred deep linking via AppsFlyer
class DeepLinkingService {
  static final DeepLinkingService _instance = DeepLinkingService._internal();
  factory DeepLinkingService() => _instance;
  DeepLinkingService._internal();

  AppsflyerSdk? _appsflyerSdk;
  StreamSubscription? _subscription;
  StreamSubscription? _uriLinkSubscription;
  bool _isInitialized = false;
  
  // Store pending deep link data for deferred deep linking
  Map<String, dynamic>? _pendingDeepLinkData;
  
  // Callback function to handle deep link navigation
  Function(Map<String, dynamic>)? _onDeepLinkReceived;

  /// Initialize AppsFlyer SDK
  Future<void> initialize({
    required bool isDebug,
    Function(Map<String, dynamic>)? onDeepLinkReceived,
  }) async {
    if (_isInitialized) {
      return;
    }

    try {
      
      // Set up deep link callback
      _onDeepLinkReceived = onDeepLinkReceived;

      // AppsFlyer SDK configuration
      final appsFlyerOptions = AppsFlyerOptions(
        afDevKey: 'TBCWz6fvHsJ2xegPPzHGJH',
        appId: Platform.isIOS ? '6755110033' : '', // iOS App ID for App Store
        showDebug: isDebug,
        timeToWaitForATTUserAuthorization: Platform.isIOS ? 60 : null, // iOS only
      );

      _appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
      
      // Set up deep link listener
      _appsflyerSdk?.onInstallConversionData((data) {
        
        // Check if this is a deferred deep link (user installed after clicking link)
        final status = data['status'];
        if (status == 'NON_ORGANIC' && data['is_first_launch'] == true) {
          _handleDeepLinkData(data);
        } else if (status == 'ORGANIC') {
        }
      });

      // Set up deep link listener for when app is already installed
      _appsflyerSdk?.onDeepLinking((DeepLinkResult result) {
        
        // Handle AppsFlyer OneLinks (FOUND status)
        if (result.deepLink != null && result.status == Status.FOUND) {
          final clickEvent = result.deepLink!.clickEvent;
          _handleDeepLinkData(clickEvent);
        } else {
        }
      });

      // Initialize AppsFlyer
      await _appsflyerSdk?.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      
      // Set up uni_links listener for custom URL schemes
      await _initUniLinks();
      
      _isInitialized = true;
    } catch (e) {
    }
  }

  /// Initialize uni_links for custom URL scheme handling
  Future<void> _initUniLinks() async {
    try {
      
      // Handle initial link (when app is opened via deep link)
      try {
        final initialLink = await getInitialUri();
        if (initialLink != null) {
          _handleDeepLink(initialLink.toString());
        } else {
        }
      } catch (e) {
      }

      // Listen for incoming links when app is already running
      _uriLinkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          if (uri != null) {
            _handleDeepLink(uri.toString());
          } else {
          }
        },
        onError: (err) {
        },
        cancelOnError: false,
      );

    } catch (e) {
    }
  }

  /// Handle deep link URL
  void _handleDeepLink(String url) {
    
    try {
      final uri = Uri.parse(url);
      
      final scheme = uri.scheme; // proplinq
      final host = uri.host; // listing, shortlet, hotel
      final pathSegments = uri.pathSegments; // [propertyId]
      
      if (scheme != 'proplinq') {
        return;
      }

      // Extract property ID from path or query parameters
      String? propertyId;
      if (pathSegments.isNotEmpty) {
        propertyId = pathSegments.first;
      } else if (uri.queryParameters.containsKey('id')) {
        propertyId = uri.queryParameters['id'];
      } else {
        // Try to extract from the path directly if pathSegments is empty
        final path = uri.path;
        if (path.isNotEmpty && path.startsWith('/')) {
          propertyId = path.substring(1); // Remove leading slash
        }
      }

      if (propertyId == null || propertyId.isEmpty) {
        return;
      }


      // Determine property type based on host
      String propertyType = 'listing'; // default
      if (host == 'shortlet') {
        propertyType = 'shortlet';
      } else if (host == 'hotel') {
        propertyType = 'hotel';
      }

      // Store pending deep link data
      _pendingDeepLinkData = {
        'propertyId': propertyId,
        'propertyType': propertyType,
        'url': url,
      };

      // Trigger navigation if callback is set
      if (_onDeepLinkReceived != null) {
        _onDeepLinkReceived!(_pendingDeepLinkData!);
      }
    } catch (e) {
    }
  }

  /// Handle AppsFlyer deep link data
  void _handleDeepLinkData(Map<String, dynamic> data) {
    try {
      
      // Extract deep link value from AppsFlyer data
      final deepLinkValue = data['deep_link_value'];
      final deepLinkSub1 = data['deep_link_sub1'];
      final deepLinkSub2 = data['deep_link_sub2'];
      final deepLinkSub3 = data['deep_link_sub3'];
      
      // Also check for custom payload
      final customPayload = data['custom'] as Map<String, dynamic>?;
      final mediaSource = data['media_source'];
      final campaign = data['campaign'];
      
      
      String? propertyId;
      String? propertyType;
      
      // Priority 1: If deep_link_value is "property_page", use deep_link_sub1 for property ID
      if (deepLinkValue != null && deepLinkValue.toString() == 'property_page') {
        propertyId = deepLinkSub1?.toString();
        // Property type can be determined from other parameters or default to listing
        propertyType = 'listing'; // Default, will be updated if found elsewhere
      }
      // Priority 2: Try to extract property ID from deep link value if it's a URL
      else if (deepLinkValue != null && deepLinkValue.toString().isNotEmpty) {
        // Check if it's a URL we can parse
        if (deepLinkValue.toString().startsWith('proplinq://')) {
          // Parse the URL
          final uri = Uri.parse(deepLinkValue.toString());
          final host = uri.host;
          final pathSegments = uri.pathSegments;
          
          if (pathSegments.isNotEmpty) {
            propertyId = pathSegments.first;
          }
          
          if (host == 'listing') {
            propertyType = 'listing';
          } else if (host == 'shortlet') {
            propertyType = 'shortlet';
          } else if (host == 'hotel') {
            propertyType = 'hotel';
          }
        } else {
          // Assume it's just a property ID
          propertyId = deepLinkValue.toString();
        }
      }
      
      // Priority 3: Try to extract from deep link sub parameters (fallback)
      if (propertyId == null) {
        propertyId = deepLinkSub1?.toString() ??
                     deepLinkSub2?.toString() ??
                     deepLinkSub3?.toString();
      }
      
      // Priority 4: Try to extract from custom payload
      if (propertyId == null && customPayload != null) {
        propertyId = customPayload['property_id']?.toString() ??
                     customPayload['propertyId']?.toString();
        propertyType = customPayload['property_type']?.toString() ??
                       customPayload['propertyType']?.toString();
      }
      
      if (propertyId != null && propertyId.isNotEmpty) {
        
        // Store pending deep link data
        _pendingDeepLinkData = {
          'propertyId': propertyId,
          'propertyType': propertyType ?? 'listing',
          'mediaSource': mediaSource,
          'campaign': campaign,
          'customPayload': customPayload,
        };

        // Trigger navigation if callback is set
        if (_onDeepLinkReceived != null) {
          _onDeepLinkReceived!(_pendingDeepLinkData!);
        }
      } else {
      }
    } catch (e) {
    }
  }

  /// Get pending deep link data (for deferred deep linking)
  Map<String, dynamic>? getPendingDeepLinkData() {
    return _pendingDeepLinkData;
  }

  /// Clear pending deep link data
  void clearPendingDeepLinkData() {
    _pendingDeepLinkData = null;
  }

  /// Set callback for deep link navigation
  void setDeepLinkCallback(Function(Map<String, dynamic>) callback) {
    _onDeepLinkReceived = callback;
  }

  /// Log custom events to AppsFlyer
  Future<void> logEvent(String eventName, Map<String, dynamic>? eventValues) async {
    try {
      if (_appsflyerSdk != null) {
        await _appsflyerSdk?.logEvent(eventName, eventValues);
      }
    } catch (e) {
    }
  }

  /// Set user ID for AppsFlyer
  void setUserId(String userId) {
    try {
      _appsflyerSdk?.setCustomerUserId(userId);
    } catch (e) {
    }
  }

  /// Clean up resources
  void dispose() {
    _subscription?.cancel();
    _uriLinkSubscription?.cancel();
    _subscription = null;
    _uriLinkSubscription = null;
    _onDeepLinkReceived = null;
    _pendingDeepLinkData = null;
  }
}

