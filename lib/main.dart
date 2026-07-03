import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/onesignal_service.dart';
import 'core/services/message_notification_service.dart';
import 'core/services/deep_linking_service.dart';
import 'core/services/deep_link_router.dart';
import 'core/animations/app_transitions.dart';
import 'core/widgets/deep_link_debug_overlay.dart';
import 'features/splash/views/second_splash_view.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Lock to portrait on all devices (phone layout, not yet iPad-adapted)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize OneSignal
  await OneSignalService().initialize();

  // Initialize message notification service (sound + local notifications)
  await MessageNotificationService().initialize();
  
  // Initialize Deep Linking Service with AppsFlyer
  final deepLinkingService = DeepLinkingService();
  final deepLinkRouter = DeepLinkRouter();
  
  // Initialize AppsFlyer SDK — deep link navigation is handled by SecondSplashView
  // after it finishes routing, to avoid race conditions with pushReplacement.
  await deepLinkingService.initialize(
    isDebug: kDebugMode,
    onDeepLinkReceived: (deepLinkData) {
      // If the navigator is ready (app already running in foreground), navigate now.
      // Otherwise the data is already stored in _pendingDeepLinkData inside
      // DeepLinkingService — SecondSplashView will pick it up after routing.
      final context = deepLinkRouter.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        deepLinkRouter.handleDeepLink(context, deepLinkData);
      }
      // No else needed — _pendingDeepLinkData is kept alive by the service.
    },
  );
  
  runApp(PropLinqApp(
    deepLinkRouter: deepLinkRouter,
    deepLinkingService: deepLinkingService,
  ));
}

class PropLinqApp extends StatelessWidget {
  final DeepLinkRouter deepLinkRouter;
  final DeepLinkingService deepLinkingService;

  const PropLinqApp({
    super.key,
    required this.deepLinkRouter,
    required this.deepLinkingService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,
      navigatorKey: deepLinkRouter.navigatorKey,
      home: const SecondSplashView(),
      builder: (context, child) {
        // Global deep-link debug overlay (temporary, self-hides until an event fires)
        return Stack(
          children: [
            if (child != null) child,
            const DeepLinkDebugOverlay(),
          ],
        );
      },
      theme: AppTheme.lightTheme.copyWith(
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: <TargetPlatform, PageTransitionsBuilder>{
            TargetPlatform.iOS: PropLinqPageTransition(),
            TargetPlatform.android: PropLinqPageTransition(),
            TargetPlatform.macOS: PropLinqPageTransition(),
          },
        ),
      ),
    );
  }
}
