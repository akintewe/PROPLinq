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
    Future.delayed(const Duration(milliseconds: 2500), () {
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
    
    // Start text slide in after a shorter delay
    Future.delayed(const Duration(milliseconds: 200), () {
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
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo and main text row
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start, // Align to top
                children: [
                  // Hero animated logo
                  SlideTransition(
                    position: _logoMoveAnimation,
                    child: Hero(
                      tag: 'splash_logo',
                      child: Image.asset(
                        'assets/icons/Layer_x0020_1.png',
                        width: 80, // Increased from 60 to 80
                        height: 80, // Increased from 60 to 80
                      ),
                    ),
                  ),
                  const SizedBox(width: 16), // Slightly more spacing
                  // Animated PROPLINQ text and tagline column
                  SlideTransition(
                    position: _textSlideAnimation,
                    child: FadeTransition(
                      opacity: _textOpacityAnimation,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // PROPLINQ text
                          RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'PROP',
                                  style: TextStyle(
                                    fontSize: 40, // Increased from 32 to 40
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4A90E2), // Blue color
                                    letterSpacing: 1.0,
                                    fontFamily: 'Gabarito',
                                  ),
                                ),
                                TextSpan(
                                  text: 'LINQ',
                                  style: TextStyle(
                                    fontSize: 40, // Increased from 32 to 40
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF4ECDC4), // Teal color
                                    letterSpacing: 1.0,
                                    fontFamily: 'Gabarito',
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 2), // Minimal spacing
                          // Tagline
                          const Text(
                            '...your link to verified homes',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.normal,
                              color: Color(0xFF4A90E2), // Same blue as PROP
                              letterSpacing: 0.5,
                              fontFamily: 'Gabarito',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
} 