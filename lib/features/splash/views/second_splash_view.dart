import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/deep_linking_service.dart';
import '../../../core/services/deep_link_router.dart';
import '../../onboarding/views/onboarding_view.dart';
import '../../auth/views/login_view.dart';
import '../../auth/views/biometric_login_view.dart';
import '../../home/views/tenant_home_view.dart';
import '../../home/views/agent_home_view.dart';
import '../../home/views/guest_home_view.dart';

class SecondSplashView extends StatefulWidget {
  const SecondSplashView({super.key});

  @override
  State<SecondSplashView> createState() => _SecondSplashViewState();
}

class _SecondSplashViewState extends State<SecondSplashView> {
  final StorageService _storageService = StorageService();
  final BiometricService _biometricService = BiometricService();

  @override
  void initState() {
    super.initState();
    
    // Check authentication status after 2 seconds
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _checkAuthenticationStatus();
      }
    });
  }

  Future<void> _checkAuthenticationStatus() async {
    try {
      // Give app_links a moment to fire the initial link before we check auth
      await Future.delayed(const Duration(milliseconds: 600));

      // Check if user is logged in
      final isLoggedIn = await _storageService.isLoggedIn();
      final token = await _storageService.getToken();

      // Deferred deep links resolve via a network call that can land AFTER the
      // splash is ready to route. On a fresh install (not logged in, onboarding
      // not seen), briefly poll for a pending deep link so a deferred property
      // link isn't lost to the onboarding path. Capped so launch never hangs.
      if (!(isLoggedIn && token != null)) {
        final hasSeenOnboarding = await _storageService.hasSeenOnboarding();
        if (!hasSeenOnboarding) {
          for (var i = 0; i < 12; i++) {
            if (DeepLinkingService().getPendingDeepLinkData() != null) break;
            await Future.delayed(const Duration(milliseconds: 250));
          }
        }
      }
      
      if (isLoggedIn && token != null) {
        // Check if remember me is enabled and still valid (within 5 days)
        final isRememberMeValid = await _storageService.isRememberMeValid();
        
        if (isRememberMeValid) {
          // Remember me is valid, skip biometric and go directly to home
          _navigateToHome();
        } else {
          // Remember me is not valid or not enabled, check biometric
        final isBiometricEnabled = await _storageService.isBiometricEnabled();
        final isBiometricAvailable = await _biometricService.isBiometricAvailable();
        
        if (isBiometricEnabled && isBiometricAvailable) {
          // Navigate to biometric login
          _navigateToBiometricLogin();
        } else {
          // Navigate to regular login
          _navigateToLogin();
          }
        }
      } else {
        // User is not logged in.
        // If a deep link is pending (e.g. a DEFERRED deep link on a fresh
        // install), skip onboarding and go straight to guest home so the
        // property opens — onboarding does not consume pending deep links.
        final pendingDeepLink =
            DeepLinkingService().getPendingDeepLinkData();
        if (pendingDeepLink != null) {
          _navigateToGuestHome();
          return;
        }
        // Show onboarding only on the very first launch; afterwards go straight to guest dashboard
        final hasSeenOnboarding = await _storageService.hasSeenOnboarding();
        if (hasSeenOnboarding) {
          _navigateToGuestHome();
        } else {
          _navigateToOnboarding();
        }
      }
    } catch (e) {
      // On error, navigate to onboarding
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
    // Mark so next cold launch goes straight to guest dashboard
    _storageService.markOnboardingSeen();
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const OnboardingView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToGuestHome() {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GuestHomeView(),
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
    _openPendingDeepLinkAfterNav();
  }

  void _navigateToLogin() {
    // If there's a pending deep link, go to guest home first so the property
    // opens immediately — the user can log in later from the guest dashboard.
    final pending = DeepLinkingService().getPendingDeepLinkData();
    if (pending != null) {
      _navigateToGuestHome();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const LoginView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  void _navigateToBiometricLogin() {
    // Same as login — if a deep link is pending, open it on guest home first.
    final pending = DeepLinkingService().getPendingDeepLinkData();
    if (pending != null) {
      _navigateToGuestHome();
      return;
    }
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) =>
            const BiometricLoginView(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  Future<void> _navigateToHome() async {
    final userType = await _storageService.getUserType();
    if (!mounted) return;

    final isAgent = userType != null && userType != 'home_seeker';
    final homeWidget = isAgent ? const AgentHomeView() : const TenantHomeView();

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => homeWidget,
        transitionsBuilder: (_, animation, __, child) =>
            FadeTransition(opacity: animation, child: child),
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );

    // After home is on screen, open property from deep link (if any)
    _openPendingDeepLinkAfterNav();
  }

  void _openPendingDeepLinkAfterNav() {
    final deepLinkingService = DeepLinkingService();
    final deepLinkRouter = DeepLinkRouter();

    // Wait for the pushReplacement transition (500ms) to fully complete before
    // pushing the property screen. 800ms gives a safe margin so the destination
    // screen is fully on the stack before we push the property on top of it.
    Future.delayed(const Duration(milliseconds: 800), () {
      final pendingData = deepLinkingService.getPendingDeepLinkData();
      if (pendingData != null) {
        deepLinkingService.clearPendingDeepLinkData();
        final navContext = deepLinkRouter.navigatorKey.currentContext;
        if (navContext != null && navContext.mounted) {
          deepLinkRouter.handleDeepLink(navContext, pendingData);
        }
      }

      // Initial routing is done — from now on, any newly arriving deep link
      // (foreground tap) should navigate live instead of being stored.
      deepLinkingService.markInitialRoutingComplete();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Centered logo - Instagram style small size
          Center(
            child: Image.asset(
              'assets/icons/PropLinq Logo-Icon-v1 (2).png',
              height: 70,
              width: 70,
              fit: BoxFit.contain,
            ),
          ),
          
          // Existing splash logo at the bottom - small Instagram style
          // Positioned(
          //   left: 0,
          //   right: 0,
          //   bottom: 80,
          //   child: Center(
          //     child: Hero(
          //       tag: 'splash_logo',
          //       child: Image.asset(
          //         'assets/icons/PropLinq Logo-v1-SVG 1 (1).png',
          //         height: 60,
          //         fit: BoxFit.contain,
          //       ),
          //     ),
          //   ),
          // ),
        ],
      ),
    );
  }
} 