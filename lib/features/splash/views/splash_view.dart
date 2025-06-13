import 'package:flutter/material.dart';
import 'second_splash_view.dart';

class SplashView extends StatefulWidget {
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView>
    with SingleTickerProviderStateMixin {
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    
    // Initialize fade animation
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    
    _fadeAnimation = Tween<double>(
      begin: 1.0,
      end: 0.0,
    ).animate(CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    ));
    
    // Start fade out after 2 seconds and navigate to second splash
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        _fadeController.forward().then((_) {
          Navigator.of(context).pushReplacement(
            PageRouteBuilder(
              pageBuilder: (context, animation, secondaryAnimation) =>
                  const SecondSplashView(),
              transitionsBuilder: (context, animation, secondaryAnimation, child) {
                return FadeTransition(opacity: animation, child: child);
              },
              transitionDuration: const Duration(milliseconds: 1200),
            ),
          );
        });
      }
    });
  }

  @override
  void dispose() {
    _fadeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background image
          Image.asset(
            'assets/images/image_2025-06-12_093807951 1.png',
            fit: BoxFit.cover,
          ),
          // Green overlay
          Container(
            color: const Color(0xFF66F3C0).withOpacity(0.9),
          ),
          // Centered logo with fade animation
          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: Hero(
                tag: 'splash_logo',
                child: Image.asset(
                  'assets/icons/Layer_x0020_1.png',
                  width: 120,
                  height: 120,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
} 