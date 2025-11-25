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
      print('⚠️ DeepLinkingService: Already initialized');
      return;
    }

    try {
      print('🚀 Initializing AppsFlyer SDK...');
      
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
        print('📥 AppsFlyer: Install conversion data received');
        print('📋 Data: $data');
        
        // Check if this is a deferred deep link (user installed after clicking link)
        final status = data['status'];
        if (status == 'NON_ORGANIC' && data['is_first_launch'] == true) {
          print('✅ Deferred deep link detected - first launch after install');
          _handleDeepLinkData(data);
        } else if (status == 'ORGANIC') {
          print('ℹ️ Organic install - no deep link data');
        }
      });

      // Set up deep link listener for when app is already installed
      _appsflyerSdk?.onDeepLinking((DeepLinkResult result) {
        print('🔗 AppsFlyer: Deep link callback triggered');
        print('📋 Status: ${result.status}');
        print('📋 Deep Link: ${result.deepLink}');
        
        // Handle AppsFlyer OneLinks (FOUND status)
        if (result.deepLink != null && result.status == Status.FOUND) {
          print('✅ AppsFlyer: Processing AppsFlyer OneLink deep link');
          final clickEvent = result.deepLink!.clickEvent;
          _handleDeepLinkData(clickEvent);
        } else {
          print('ℹ️ AppsFlyer: NOT_FOUND - Custom URL scheme or non-AppsFlyer link');
          print('   This is expected for proplinq:// links - uni_links will handle it');
        }
      });

      // Initialize AppsFlyer
      await _appsflyerSdk?.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );

      print('✅ AppsFlyer SDK initialized successfully');
      
      // Set up uni_links listener for custom URL schemes
      await _initUniLinks();
      
      _isInitialized = true;
    } catch (e) {
      print('❌ Error initializing AppsFlyer SDK: $e');
    }
  }

  /// Initialize uni_links for custom URL scheme handling
  Future<void> _initUniLinks() async {
    try {
      print('🔗 Initializing uni_links for custom URL schemes...');
      
      // Handle initial link (when app is opened via deep link)
      try {
        print('🔍 Checking for initial deep link...');
        final initialLink = await getInitialUri();
        print('🔍 Initial link check result: $initialLink');
        if (initialLink != null) {
          print('📥 Initial deep link found: $initialLink');
          print('   Full URI: $initialLink');
          print('   Scheme: ${initialLink.scheme}');
          print('   Host: ${initialLink.host}');
          print('   Path: ${initialLink.path}');
          _handleDeepLink(initialLink.toString());
        } else {
          print('ℹ️ No initial deep link found');
        }
      } catch (e) {
        print('⚠️ Error getting initial link: $e');
      }

      // Listen for incoming links when app is already running
      _uriLinkSubscription = uriLinkStream.listen(
        (Uri? uri) {
          print('🔔 uni_links: Received URI in stream: $uri');
          if (uri != null) {
            print('📥 Deep link received while app is running: $uri');
            print('   Scheme: ${uri.scheme}');
            print('   Host: ${uri.host}');
            print('   Path: ${uri.path}');
            print('   Path segments: ${uri.pathSegments}');
            _handleDeepLink(uri.toString());
          } else {
            print('⚠️ uni_links: Received null URI');
          }
        },
        onError: (err) {
          print('❌ Error listening to deep links: $err');
        },
        cancelOnError: false,
      );

      print('✅ uni_links initialized successfully');
    } catch (e) {
      print('❌ Error initializing uni_links: $e');
    }
  }

  /// Handle deep link URL
  void _handleDeepLink(String url) {
    print('🔗 Processing deep link: $url');
    
    try {
      final uri = Uri.parse(url);
      print('   Parsed URI - Scheme: ${uri.scheme}, Host: ${uri.host}, Path: ${uri.path}');
      print('   Path segments: ${uri.pathSegments}');
      print('   Query params: ${uri.queryParameters}');
      
      final scheme = uri.scheme; // proplinq
      final host = uri.host; // listing, shortlet, hotel
      final pathSegments = uri.pathSegments; // [propertyId]
      
      if (scheme != 'proplinq') {
        print('⚠️ Unsupported deep link scheme: $scheme');
        return;
      }

      // Extract property ID from path or query parameters
      String? propertyId;
      if (pathSegments.isNotEmpty) {
        propertyId = pathSegments.first;
        print('   Extracted property ID from pathSegments: $propertyId');
      } else if (uri.queryParameters.containsKey('id')) {
        propertyId = uri.queryParameters['id'];
        print('   Extracted property ID from query params: $propertyId');
      } else {
        // Try to extract from the path directly if pathSegments is empty
        final path = uri.path;
        if (path.isNotEmpty && path.startsWith('/')) {
          propertyId = path.substring(1); // Remove leading slash
          print('   Extracted property ID from path: $propertyId');
        }
      }

      if (propertyId == null || propertyId.isEmpty) {
        print('⚠️ No property ID found in deep link');
        print('   URL: $url');
        print('   Scheme: $scheme, Host: $host, Path: ${uri.path}');
        return;
      }

      print('✅ Parsed deep link - Type: $host, Property ID: $propertyId');

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
      print('❌ Error parsing deep link: $e');
    }
  }

  /// Handle AppsFlyer deep link data
  void _handleDeepLinkData(Map<String, dynamic> data) {
    try {
      print('📋 Processing AppsFlyer deep link data...');
      
      // Extract deep link value from AppsFlyer data
      final deepLinkValue = data['deep_link_value'];
      final deepLinkSub1 = data['deep_link_sub1'];
      final deepLinkSub2 = data['deep_link_sub2'];
      final deepLinkSub3 = data['deep_link_sub3'];
      
      // Also check for custom payload
      final customPayload = data['custom'] as Map<String, dynamic>?;
      final mediaSource = data['media_source'];
      final campaign = data['campaign'];
      
      print('📋 Deep Link Value: $deepLinkValue');
      print('📋 Media Source: $mediaSource');
      print('📋 Campaign: $campaign');
      print('📋 Custom Payload: $customPayload');
      
      String? propertyId;
      String? propertyType;
      
      // Try to extract property ID from deep link value
      if (deepLinkValue != null && deepLinkValue.toString().isNotEmpty) {
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
      
      // Try to extract from custom payload
      if (propertyId == null && customPayload != null) {
        propertyId = customPayload['property_id']?.toString() ??
                     customPayload['propertyId']?.toString();
        propertyType = customPayload['property_type']?.toString() ??
                       customPayload['propertyType']?.toString();
      }
      
      // Try to extract from deep link sub parameters
      if (propertyId == null) {
        propertyId = deepLinkSub1?.toString() ??
                     deepLinkSub2?.toString() ??
                     deepLinkSub3?.toString();
      }
      
      if (propertyId != null && propertyId.isNotEmpty) {
        print('✅ Extracted Property ID: $propertyId, Type: $propertyType');
        
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
        print('⚠️ Could not extract property ID from AppsFlyer data');
      }
    } catch (e) {
      print('❌ Error handling AppsFlyer deep link data: $e');
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
        print('📊 AppsFlyer: Logged event $eventName');
      }
    } catch (e) {
      print('❌ Error logging AppsFlyer event: $e');
    }
  }

  /// Set user ID for AppsFlyer
  void setUserId(String userId) {
    try {
      _appsflyerSdk?.setCustomerUserId(userId);
      print('👤 AppsFlyer: Set user ID to $userId');
    } catch (e) {
      print('❌ Error setting AppsFlyer user ID: $e');
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

