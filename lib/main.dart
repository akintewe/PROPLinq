import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/onesignal_service.dart';
import 'core/services/deep_linking_service.dart';
import 'core/services/deep_link_router.dart';
import 'features/splash/views/second_splash_view.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize OneSignal
  await OneSignalService().initialize();
  
  // Initialize Deep Linking Service with AppsFlyer
  final deepLinkingService = DeepLinkingService();
  final deepLinkRouter = DeepLinkRouter();
  
  // Set up deep link callback
  deepLinkingService.setDeepLinkCallback((deepLinkData) {
    print('🔗 Main: Deep link callback received');
    print('📋 Deep Link Data: $deepLinkData');
    
    // Use the router to handle navigation
    // Note: Context might not be available immediately, so we'll handle it after app initializes
    Future.delayed(const Duration(milliseconds: 500), () {
      final context = deepLinkRouter.navigatorKey.currentContext;
      if (context != null) {
        deepLinkRouter.handleDeepLink(context, deepLinkData);
      } else {
        print('⚠️ Main: Context not available yet, storing deep link data');
        // Deep link will be handled when app is ready
      }
    });
  });
  
  // Initialize AppsFlyer SDK
  await deepLinkingService.initialize(
    isDebug: kDebugMode,
    onDeepLinkReceived: (deepLinkData) {
      print('🔗 Main: Deep link received in callback');
      deepLinkRouter.handleDeepLink(null, deepLinkData);
    },
  );
  
  runApp(PropLinqApp(
    deepLinkRouter: deepLinkRouter,
    deepLinkingService: deepLinkingService,
  ));
}

class PropLinqApp extends StatefulWidget {
  final DeepLinkRouter deepLinkRouter;
  final DeepLinkingService deepLinkingService;
  
  const PropLinqApp({
    super.key,
    required this.deepLinkRouter,
    required this.deepLinkingService,
  });

  @override
  State<PropLinqApp> createState() => _PropLinqAppState();
}

class _PropLinqAppState extends State<PropLinqApp> {
  @override
  void initState() {
    super.initState();
    
    // Check for pending deep link after a delay (allowing app to initialize)
    Future.delayed(const Duration(seconds: 3), () {
      _checkPendingDeepLink();
    });
  }
  
  void _checkPendingDeepLink() {
    final pendingData = widget.deepLinkingService.getPendingDeepLinkData();
    if (pendingData != null) {
      print('📥 Main: Found pending deep link data, handling...');
      final context = widget.deepLinkRouter.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        widget.deepLinkRouter.handleDeepLink(context, pendingData);
        widget.deepLinkingService.clearPendingDeepLinkData();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      navigatorKey: widget.deepLinkRouter.navigatorKey,
      home: const SecondSplashView(),
    );
  }
}
