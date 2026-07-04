import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep linking and deferred deep linking via AppsFlyer
class DeepLinkingService {
  static final DeepLinkingService _instance = DeepLinkingService._internal();
  factory DeepLinkingService() => _instance;
  DeepLinkingService._internal();

  // ── On-screen debug log ─────────────────────────────────────────────
  // Visible overlay so deep-link flow can be inspected without a cable.
  // Remove once the flow is confirmed working.
  static final ValueNotifier<List<String>> debugLog =
      ValueNotifier<List<String>>(<String>[]);

  static void _dbg(String msg) {
    final ts = DateTime.now().toIso8601String().substring(11, 23);
    final line = '$ts  $msg';
    debugLog.value = [...debugLog.value, line];
    // ignore: avoid_print
    print('🔗 $line');
  }

  AppsflyerSdk? _appsflyerSdk;
  StreamSubscription? _subscription;
  StreamSubscription? _uriLinkSubscription;
  bool _isInitialized = false;
  final AppLinks _appLinks = AppLinks();
  
  // Store pending deep link data for deferred deep linking
  Map<String, dynamic>? _pendingDeepLinkData;

  // Callback function to handle deep link navigation
  Function(Map<String, dynamic>)? _onDeepLinkReceived;

  // True once the splash has finished its initial routing. Until then, deep
  // links must only be STORED (not navigated live) — otherwise the splash's
  // pushReplacement wipes out the property screen we just pushed. The splash
  // calls markInitialRoutingComplete() after it consumes any pending link.
  bool _initialRoutingComplete = false;

  /// Called by the splash once it has finished routing (home/guest/login) and
  /// consumed any pending deep link. After this, live links navigate immediately.
  void markInitialRoutingComplete() {
    _initialRoutingComplete = true;
  }

  bool get isInitialRoutingComplete => _initialRoutingComplete;

  /// Initialize AppsFlyer SDK
  Future<void> initialize({
    required bool isDebug,
    Function(Map<String, dynamic>)? onDeepLinkReceived,
  }) async {
    if (_isInitialized) {
      return;
    }

    try {
      print('🔵 [DeepLinkingService] Initializing AppsFlyer SDK...');
      print('   - Platform: ${Platform.isAndroid ? "Android" : "iOS"}');
      print('   - Dev Key: TBCWz6fvHsJ2xegPPzHGJH');
      print('   - Debug Mode: $isDebug');
      
      // Set up deep link callback
      _onDeepLinkReceived = onDeepLinkReceived;

      // AppsFlyer SDK configuration
      final appsFlyerOptions = AppsFlyerOptions(
        afDevKey: 'TBCWz6fvHsJ2xegPPzHGJH',
        appId: Platform.isIOS ? '6755110033' : '', // iOS App ID for App Store (Android doesn't need appId)
        showDebug: isDebug,
        timeToWaitForATTUserAuthorization: Platform.isIOS ? 60 : null, // iOS only
      );

      _appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
      print('✅ [DeepLinkingService] AppsFlyer SDK instance created');
      
      // Set up deep link listener
      _appsflyerSdk?.onInstallConversionData((data) {
        final status = data['status'];
        _dbg('onInstallConversionData: status=$status first=${data['is_first_launch']}');
        // Check if this is a deferred deep link (user installed after clicking link)
        if (status == 'NON_ORGANIC' && data['is_first_launch'] == true) {
          _handleDeepLinkData(data);
        }
      });

      // Set up deep link listener for when app is already installed
      _appsflyerSdk?.onDeepLinking((DeepLinkResult result) {
        _dbg('onDeepLinking fired: status=${result.status}');
        _dbg('  clickEvent=${result.deepLink?.clickEvent}');
        if (result.error != null) _dbg('  error=${result.error}');

        if (result.deepLink != null && result.status == Status.FOUND) {
          final clickEvent = result.deepLink!.clickEvent;
          _handleDeepLinkData(clickEvent);
        }
      });

      // Initialize AppsFlyer
      print('🔵 [DeepLinkingService] Calling initSdk...');
      await _appsflyerSdk?.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: false,
        registerOnDeepLinkingCallback: true,
      );
      print('✅ [DeepLinkingService] AppsFlyer SDK initialized successfully');

      
      // Set up uni_links listener for custom URL schemes
      await _initUniLinks();
      
      _isInitialized = true;
      print('✅ [DeepLinkingService] Deep linking service fully initialized');
    } catch (e, stackTrace) {
      print('❌ [DeepLinkingService] Error initializing AppsFlyer SDK: $e');
      print('   - Stack trace: $stackTrace');
    }
  }

  /// Initialize app_links for custom URL scheme handling
  Future<void> _initUniLinks() async {
    try {
      
      // Handle initial link (when app is opened via deep link)
      try {
        final initialLink = await _appLinks.getInitialLink();
        if (initialLink != null) {
          _dbg('app_links initialLink: $initialLink');
          _handleDeepLink(initialLink.toString());
        } else {
          _dbg('app_links initialLink: none');
        }
      } catch (e) {
        _dbg('app_links initialLink error: $e');
      }

      // Listen for incoming links when app is already running
      _uriLinkSubscription = _appLinks.uriLinkStream.listen(
        (Uri uri) {
          _dbg('app_links stream: $uri');
          _handleDeepLink(uri.toString());
        },
        onError: (err) {
          _dbg('app_links stream error: $err');
        },
        cancelOnError: false,
      );

    } catch (e) {
    }
  }

  /// Handle deep link URL.
  /// Supported formats:
  ///   proplinq://{property_type}/{property_id}
  ///   https://proplinq.com/property/{property_type}/{property_id}
  void _handleDeepLink(String url) {
    try {
      _dbg('_handleDeepLink: $url');
      final uri = Uri.parse(url);
      String? propertyId;
      String propertyType = 'apartment';

      if (uri.scheme == 'proplinq') {
        final host = uri.host;
        final segments = uri.pathSegments;
        propertyId = segments.isNotEmpty ? segments.first : null;
        if (host == 'hotel' || host == 'shortlet' || host == 'apartment') {
          propertyType = host;
        }
      } else if (uri.scheme == 'https' && uri.host == 'proplinq.onelink.me') {
        // AppsFlyer OneLink — extract deep_link_value query param
        // Format: deep_link_value=property/shortlet/UUID
        final deepLinkValue = uri.queryParameters['deep_link_value'];
        if (deepLinkValue != null && deepLinkValue.isNotEmpty) {
          final segments = deepLinkValue.split('/').where((s) => s.isNotEmpty).toList();
          if (segments.length >= 3 && segments[0] == 'property') {
            propertyType = segments[1];
            propertyId = segments[2];
          } else if (segments.length >= 2) {
            propertyType = segments[segments.length - 2];
            propertyId = segments[segments.length - 1];
          } else if (segments.isNotEmpty) {
            propertyId = segments.last;
          }
        }
      } else if (uri.scheme == 'https' &&
          (uri.host == 'www.proplinq.com' || uri.host == 'proplinq.com') &&
          uri.pathSegments.length >= 3 &&
          uri.pathSegments[0] == 'property') {
        propertyType = uri.pathSegments[1];
        propertyId = uri.pathSegments[2];
      } else {
        _dbg('_handleDeepLink: no matching host/scheme, ignored');
        return;
      }

      if (propertyId == null || propertyId.isEmpty) {
        _dbg('_handleDeepLink: parsed but no propertyId');
        return;
      }

      _dbg('_handleDeepLink: parsed type=$propertyType id=$propertyId');

      final data = {
        'propertyId': propertyId,
        'propertyType': propertyType,
        'url': url,
      };

      _dispatch(data);
    } catch (e) {
      _dbg('_handleDeepLink error: $e');
    }
  }

  /// Route a resolved deep link. During the splash's initial routing phase we
  /// only STORE the link (splash consumes it after routing finishes). Once the
  /// app is past the splash, we navigate live.
  void _dispatch(Map<String, dynamic> data) {
    // Always keep a copy so the splash can consume it, even if we also fire live.
    _pendingDeepLinkData = data;

    if (_initialRoutingComplete && _onDeepLinkReceived != null) {
      _dbg('_dispatch: firing live (post-splash)');
      _onDeepLinkReceived!(data);
    } else {
      _dbg('_dispatch: stored pending (splash will consume)');
    }
  }

  /// Handle AppsFlyer deep link data
  void _handleDeepLinkData(Map<String, dynamic> data) {
    try {
      _dbg('_handleDeepLinkData: dlv=${data['deep_link_value']} sub1=${data['deep_link_sub1']}');
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
        propertyType = 'apartment';
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
          
          if (host == 'apartment' || host == 'listing') {
            propertyType = 'apartment';
          } else if (host == 'shortlet') {
            propertyType = 'shortlet';
          } else if (host == 'hotel') {
            propertyType = 'hotel';
          }
        } else if (deepLinkValue.toString().startsWith('http://') ||
                   deepLinkValue.toString().startsWith('https://')) {
          // Full web URL — parse path segments: /property/{type}/{uuid}
          final uri = Uri.tryParse(deepLinkValue.toString());
          if (uri != null) {
            final segments = uri.pathSegments;
            // Expected: ['property', 'shortlet', '<uuid>']
            if (segments.length >= 3 && segments[0] == 'property') {
              propertyType = segments[1];
              propertyId = segments[2];
            } else if (segments.length >= 2) {
              propertyType = segments[segments.length - 2];
              propertyId = segments[segments.length - 1];
            } else if (segments.isNotEmpty) {
              propertyId = segments.last;
            }
          }
        } else {
          // May be a bare path like "property/shortlet/<uuid>" or just a UUID
          final value = deepLinkValue.toString();
          final segments = value.split('/').where((s) => s.isNotEmpty).toList();
          if (segments.length >= 3 && segments[0] == 'property') {
            // property/{type}/{uuid}
            propertyType = segments[1];
            propertyId = segments[2];
          } else if (segments.length >= 2) {
            // {type}/{uuid}
            propertyType = segments[segments.length - 2];
            propertyId = segments[segments.length - 1];
          } else {
            // Plain UUID
            propertyId = value;
          }
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
        _dbg('_handleDeepLinkData: routed type=$propertyType id=$propertyId');
        _dispatch({
          'propertyId': propertyId,
          'propertyType': propertyType ?? 'apartment',
          'mediaSource': mediaSource,
          'campaign': campaign,
          'customPayload': customPayload,
        });
      } else {
        _dbg('_handleDeepLinkData: no propertyId resolved');
      }
    } catch (e) {
      _dbg('_handleDeepLinkData error: $e');
    }
  }

  /// Get pending deep link data (for deferred deep linking)
  Map<String, dynamic>? getPendingDeepLinkData() {
    return _pendingDeepLinkData;
  }

  /// Store a deep link to be consumed later (e.g. when context isn't ready yet)
  void storePendingDeepLink(Map<String, dynamic> data) {
    _pendingDeepLinkData = data;
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

