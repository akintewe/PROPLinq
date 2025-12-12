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
      // First, check if there's a pending deep link
      // Give uni_links a moment to process the initial link
      await Future.delayed(const Duration(milliseconds: 500));
      
      final deepLinkingService = DeepLinkingService();
      final pendingDeepLink = deepLinkingService.getPendingDeepLinkData();
      
      if (pendingDeepLink != null) {
      }
      
      // Check if user is logged in
      final isLoggedIn = await _storageService.isLoggedIn();
      final token = await _storageService.getToken();
      
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
        // User is not logged in, navigate to onboarding
        _navigateToOnboarding();
      }
    } catch (e) {
      // On error, navigate to onboarding
      _navigateToOnboarding();
    }
  }

  void _navigateToOnboarding() {
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

  void _navigateToLogin() {
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
    // Get user type to determine which home screen to show
    final userType = await _storageService.getUserType();
    
    if (!mounted) return;
    
    // Check for pending deep link before navigating
    _handlePendingDeepLink();
    
    // Navigate based on user type
    if (userType == 'agent') {
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const AgentHomeView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    } else {
      // Default to tenant home for 'home_seeker' or any other type
      Navigator.of(context).pushReplacement(
        PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) =>
              const TenantHomeView(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            return FadeTransition(opacity: animation, child: child);
          },
          transitionDuration: const Duration(milliseconds: 500),
        ),
      );
    }
  }
  
  /// Handle pending deep link after navigation
  void _handlePendingDeepLink() {
    // Wait a bit longer to ensure navigation is complete
    Future.delayed(const Duration(milliseconds: 1500), () async {
      if (!mounted) return;
      
      final deepLinkingService = DeepLinkingService();
      final pendingData = deepLinkingService.getPendingDeepLinkData();
      
      if (pendingData != null) {
        final deepLinkRouter = DeepLinkRouter();
        
        // Get context from navigator key - try multiple times
        BuildContext? navContext;
        for (int i = 0; i < 5; i++) {
          navContext = deepLinkRouter.navigatorKey.currentContext;
          if (navContext != null && navContext.mounted) {
            break;
          }
          await Future.delayed(const Duration(milliseconds: 500));
        }
        
        if (navContext != null && navContext.mounted) {
          deepLinkRouter.handleDeepLink(navContext, pendingData);
          // Clear after a delay to allow error messages to show
          Future.delayed(const Duration(seconds: 1), () {
            deepLinkingService.clearPendingDeepLinkData();
          });
        } else {
          // Clear the deep link so app doesn't get stuck
          deepLinkingService.clearPendingDeepLinkData();
        }
      } else {
      }
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