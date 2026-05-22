import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_strings.dart';
import 'core/services/onesignal_service.dart';
import 'core/services/message_notification_service.dart';
import 'core/services/deep_linking_service.dart';
import 'core/services/deep_link_router.dart';
import 'core/animations/app_transitions.dart';
import 'features/splash/views/second_splash_view.dart';

void main() async {
  // Ensure Flutter binding is initialized
  WidgetsFlutterBinding.ensureInitialized();
  
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
      // App already running (foreground link) — navigate immediately if context ready,
      // otherwise stash for splash to pick up.
      final context = deepLinkRouter.navigatorKey.currentContext;
      if (context != null && context.mounted) {
        deepLinkRouter.handleDeepLink(context, deepLinkData);
      } else {
        deepLinkingService.storePendingDeepLink(deepLinkData);
      }
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
