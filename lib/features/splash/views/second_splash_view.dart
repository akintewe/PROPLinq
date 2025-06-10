import 'package:flutter/material.dart';
import '../../onboarding/views/onboarding_view.dart';

class SecondSplashView extends StatefulWidget {
  const SecondSplashView({super.key});

  @override
  State<SecondSplashView> createState() => _SecondSplashViewState();
}

class _SecondSplashViewState extends State<SecondSplashView> {
  @override
  void initState() {
    super.initState();
    
    // Navigate to onboarding after 6 seconds to let GIF play well
    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) {
        _navigateToOnboarding();
      }
    });
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Animated GIF background - covers full screen
          SizedBox.expand(
            child: Image.asset(
              'assets/videos/7578838-uhd_2160_3840_30fps.gif',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                // Fallback in case GIF fails to load
                return Container(
                  color: Colors.black,
                  child: const Center(
                    child: Text(
                      'PropLinq',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          
          // Dark gradient overlay at the bottom
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: 200, // Height of gradient overlay
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Colors.black.withOpacity(0.3),
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.9),
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),
          
          // Logo at the bottom - positioned higher
          Positioned(
            left: 0,
            right: 0,
            bottom: 80, // Moved up from 40 to 80
            child: Center(
              child: Hero(
                tag: 'splash_logo',
                child: Image.asset(
                  'assets/icons/PropLinq Logo-v1-SVG 1 (1).png',
                  height: 50,
                  fit: BoxFit.contain,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 