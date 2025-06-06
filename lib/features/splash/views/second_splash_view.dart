import 'package:flutter/material.dart';
import '../../onboarding/views/onboarding_view.dart';

class SecondSplashView extends StatefulWidget {
  const SecondSplashView({super.key});

  @override
  State<SecondSplashView> createState() => _SecondSplashViewState();
}

class _SecondSplashViewState extends State<SecondSplashView>
    with TickerProviderStateMixin {
  late AnimationController _fadeController;
  late AnimationController _logoMoveController;
  late AnimationController _textSlideController;
  
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _logoMoveAnimation;
  late Animation<Offset> _textSlideAnimation;
  late Animation<double> _textOpacityAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize animation controllers
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _logoMoveController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    
    _textSlideController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    // Logo move animation (from center to left position)
    _logoMoveAnimation = Tween<Offset>(
      begin: const Offset(0.15, 0), // Start slightly right of final position
      end: Offset.zero, // End at final position
    ).animate(CurvedAnimation(
      parent: _logoMoveController,
      curve: Curves.easeOutCubic,
    ));
    
    // Text slide animation (slide in from right)
    _textSlideAnimation = Tween<Offset>(
      begin: const Offset(0.5, 0), // Start from right
      end: Offset.zero, // End at final position
    ).animate(CurvedAnimation(
      parent: _textSlideController,
      curve: Curves.easeOutCubic,
    ));
    
    // Text opacity animation
    _textOpacityAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _textSlideController,
      curve: Curves.easeInOut,
    ));
    
    // Fade out animation for transition to onboarding
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start animations with delays
    _startAnimations();
    
    // Navigate to onboarding after delay
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        _fadeController.forward().then((_) {
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
        });
      }
    });
  }
  
  void _startAnimations() {
    // Start logo movement immediately
    _logoMoveController.forward();
    
    // Start text slide in after a short delay
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        _textSlideController.forward();
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    _logoMoveController.dispose();
    _textSlideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnimation,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated Logo
              SlideTransition(
                position: _logoMoveAnimation,
                child: Hero(
                  tag: 'splash_logo',
                  child: Image.asset(
                    'assets/icons/Layer_x0020_1.png',
                    width: 60,
                    height: 60,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              // Animated Text
              SlideTransition(
                position: _textSlideAnimation,
                child: FadeTransition(
                  opacity: _textOpacityAnimation,
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'PROP',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4A90E2), // Blue color
                            letterSpacing: 1.0,
                          ),
                        ),
                        TextSpan(
                          text: 'LINQ',
                          style: TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF4ECDC4), // Teal color
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 