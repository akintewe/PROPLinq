import 'package:flutter/material.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/biometric_service.dart';
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
      // Check if user is logged in
      final isLoggedIn = await _storageService.isLoggedIn();
      final token = await _storageService.getToken();
      
      if (isLoggedIn && token != null) {
        // Check if remember me is enabled and still valid (within 5 days)
        final isRememberMeValid = await _storageService.isRememberMeValid();
        
        if (isRememberMeValid) {
          // Remember me is valid, skip biometric and go directly to home
          print('✅ Remember me is valid, navigating directly to home');
          _navigateToHome();
        } else {
          // Remember me is not valid or not enabled, check biometric
        final isBiometricEnabled = await _storageService.isBiometricEnabled();
        final isBiometricAvailable = await _biometricService.isBiometricAvailable();
        
        if (isBiometricEnabled && isBiometricAvailable) {
          // Navigate to biometric login
            print('🔐 Remember me not valid, navigating to biometric login');
          _navigateToBiometricLogin();
        } else {
          // Navigate to regular login
            print('🔑 Remember me not valid, navigating to regular login');
          _navigateToLogin();
          }
        }
      } else {
        // User is not logged in, navigate to onboarding
        print('👋 User not logged in, navigating to onboarding');
        _navigateToOnboarding();
      }
    } catch (e) {
      print('❌ Error checking authentication status: $e');
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