import 'dart:async';
import 'dart:io';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import 'package:app_links/app_links.dart';

/// Service to handle deep linking and deferred deep linking via AppsFlyer
class DeepLinkingService {
  static final DeepLinkingService _instance = DeepLinkingService._internal();
  factory DeepLinkingService() => _instance;
  DeepLinkingService._internal();

  // Lightweight console logging for the deep-link flow (no on-screen UI).
  static void _dbg(String msg) {
    // ignore: avoid_print
    print('🔗 [DeepLink] $msg');
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
      // NOTE: showDebug is forced true TEMPORARILY so AppsFlyer's own SDK debug
      // logs are emitted in the TestFlight/release build. AppsFlyer support
      // (#1003139) requires these logs as a .txt to diagnose the Universal Link
      // Safari-bounce. Revert to `isDebug` once the ticket is resolved.
      final appsFlyerOptions = AppsFlyerOptions(
        afDevKey: 'TBCWz6fvHsJ2xegPPzHGJH',
        appId: Platform.isIOS ? '6755110033' : '', // iOS App ID for App Store (Android doesn't need appId)
        showDebug: true, // TEMP: force on for AppsFlyer support logs (was isDebug)
        timeToWaitForATTUserAuthorization: Platform.isIOS ? 60 : null, // iOS only
      );

      _appsflyerSdk = AppsflyerSdk(appsFlyerOptions);
      print('✅ [DeepLinkingService] AppsFlyer SDK instance created');
      
      // Set up deep link listener (deferred deep linking on first launch)
      _appsflyerSdk?.onInstallConversionData((data) {
        // AppsFlyer sends status under 'af_status' or 'status'; is_first_launch
        // and is_deferred may arrive as bool OR string, so normalise both.
        final status = (data['af_status'] ?? data['status'])?.toString();
        final firstRaw = data['is_first_launch'];
        final isFirstLaunch =
            firstRaw == true || firstRaw?.toString() == 'true';
        final deferredRaw = data['is_deferred'];
        final isDeferred =
            deferredRaw == true || deferredRaw?.toString() == 'true';
        _dbg('onInstallConversionData: status=$status '
            'first=$isFirstLaunch deferred=$isDeferred');
        _dbg('  full data=$data');
        // Handle the deferred deep link on the first non-organic launch.
        if (status == 'Non-organic' ||
            status == 'NON_ORGANIC' ||
            isDeferred) {
          if (isFirstLaunch || isDeferred) {
            _dbg('  -> processing deferred conversion data');
            _handleDeepLinkData(data);
          }
        }
      });

      // Set up deep link listener for when app is already installed
      _appsflyerSdk?.onDeepLinking((DeepLinkResult result) {
        _dbg('onDeepLinking fired: status=${result.status}');
        final clickEvent = result.deepLink?.clickEvent;
        _dbg('  clickEvent=$clickEvent');
        if (result.error != null) _dbg('  error=${result.error}');

        // Process whenever we actually have deep-link data, regardless of the
        // exact status enum. In practice the clickEvent carries the property
        // params (deep_link_value/sub1/sub2) even when the status check is
        // finicky across SDK/plugin versions.
        if (clickEvent != null &&
            (clickEvent['deep_link_value'] != null ||
                clickEvent['deep_link_sub1'] != null)) {
          _dbg('  -> processing clickEvent data');
          _handleDeepLinkData(clickEvent);
        } else {
          _dbg('  -> no deep-link data in clickEvent (status=${result.status})');
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

      // AppsFlyer-wrapped URLs (proplinq://af?..., or any carrying af_deeplink/
      // shortlink) are ALSO delivered to the AppsFlyer SDK's onDeepLinking
      // callback, which resolves them reliably. If we also process them here via
      // app_links, the same link is handled twice — causing a duplicate property
      // page and a stuck-loading state. Let the SDK own these; skip here.
      final isAppsFlyerWrapped = uri.host == 'af' ||
          uri.queryParameters.containsKey('af_deeplink') ||
          uri.queryParameters.containsKey('shortlink');
      if (isAppsFlyerWrapped) {
        _dbg('_handleDeepLink: AppsFlyer-wrapped URL, deferring to SDK onDeepLinking');
        return;
      }

      if (uri.scheme == 'proplinq') {
        // Two shapes arrive on this scheme:
        //  (a) our own path form:  proplinq://shortlet/UUID
        //  (b) AppsFlyer fallback: proplinq://?deep_link_value=property_page
        //        &deep_link_sub1=UUID&deep_link_sub2=type
        final q = uri.queryParameters;
        if (q['deep_link_sub1'] != null || q['deep_link_value'] != null) {
          propertyId = q['deep_link_sub1'];
          final sub2 = q['deep_link_sub2'];
          propertyType = (sub2 != null && sub2.isNotEmpty) ? sub2 : 'apartment';
        } else {
          final host = uri.host;
          final segments = uri.pathSegments;
          propertyId = segments.isNotEmpty ? segments.first : null;
          if (host == 'hotel' || host == 'shortlet' || host == 'apartment') {
            propertyType = host;
          }
        }
      } else if (uri.scheme == 'https' && uri.host == 'proplinq.onelink.me') {
        // AppsFlyer OneLink. Preferred convention: deep_link_value=property_page
        // with deep_link_sub1=UUID and deep_link_sub2=type.
        final q = uri.queryParameters;
        final dlv = q['deep_link_value'];
        if (dlv == 'property_page') {
          propertyId = q['deep_link_sub1'];
          final sub2 = q['deep_link_sub2'];
          propertyType = (sub2 != null && sub2.isNotEmpty) ? sub2 : 'apartment';
        } else if (dlv != null && dlv.contains('/')) {
          // Legacy format: deep_link_value=property/shortlet/UUID
          final segments = dlv.split('/').where((s) => s.isNotEmpty).toList();
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

  // Guards against opening the same property twice in quick succession. The
  // same link can arrive via BOTH app_links and the AppsFlyer SDK callback, and
  // multiple launch entry points (Universal Link, return-from-Safari, the
  // "Open in app?" prompt) each re-deliver it — which caused duplicate property
  // pages and a stuck-loading state.
  String? _lastDispatchedId;
  DateTime? _lastDispatchedAt;

  /// Route a resolved deep link. During the splash's initial routing phase we
  /// only STORE the link (splash consumes it after routing finishes). Once the
  /// app is past the splash, we navigate live.
  void _dispatch(Map<String, dynamic> data) {
    final id = data['propertyId']?.toString();

    // De-duplicate: ignore the same property re-dispatched within 5 seconds.
    final now = DateTime.now();
    if (id != null &&
        id == _lastDispatchedId &&
        _lastDispatchedAt != null &&
        now.difference(_lastDispatchedAt!).inSeconds < 5) {
      _dbg('_dispatch: duplicate of $id within 5s, ignored');
      return;
    }
    _lastDispatchedId = id;
    _lastDispatchedAt = now;

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
      
      // Priority 1: If deep_link_value is "property_page" (AppsFlyer convention),
      // deep_link_sub1 holds the property UUID and deep_link_sub2 the type.
      if (deepLinkValue != null && deepLinkValue.toString() == 'property_page') {
        propertyId = deepLinkSub1?.toString();
        final sub2 = deepLinkSub2?.toString();
        propertyType = (sub2 != null && sub2.isNotEmpty) ? sub2 : 'apartment';
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

