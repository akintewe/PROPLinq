import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/gradient_button.dart';

class SavedView extends StatelessWidget {
  final bool isAgent;
  
  const SavedView({super.key, this.isAgent = false});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              const Text(
                'Saved',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Empty state
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Illustration
                      Transform.translate(
                        offset: const Offset(0, 20),
                        child: SizedBox(
                          width: 180,
                          height: 180,
                          child: Image.asset(
                            'assets/icons/Frame 171.png',
                            fit: BoxFit.contain,
                            errorBuilder: (context, error, stackTrace) {
                              return Container(
                                width: 180,
                                height: 180,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF8F9FA),
                                  borderRadius: BorderRadius.circular(20),
                                ),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    // Heart icon with house illustration
                                    Positioned(
                                      top: 40,
                                      left: 60,
                                      child: Container(
                                        width: 40,
                                        height: 40,
                                        decoration: const BoxDecoration(
                                          color: Colors.red,
                                          shape: BoxShape.circle,
                                        ),
                                        child: const Icon(
                                          Icons.favorite,
                                          color: Colors.white,
                                          size: 24,
                                        ),
                                      ),
                                    ),
                                    // House illustration placeholder
                                    Positioned(
                                      bottom: 60,
                                      child: Container(
                                        width: 120,
                                        height: 80,
                                        decoration: BoxDecoration(
                                          color: const Color(0xFF8B4513),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: const Icon(
                                          Icons.home,
                                          color: Colors.white,
                                          size: 40,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      
                      // Title
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: const Text(
                          'No Saved Property',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: const SizedBox(height: 4),
                      ),
                      
                      // Description
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: const Text(
                          'Start exploring listings and tap the heart icon to save your favorites. Head back to the homepage to begin.',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF666666),
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                      
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: const SizedBox(height: 8),
                      ),
                      
                      // Explore home button
                      Transform.translate(
                        offset: const Offset(0, -30),
                        child: SizedBox(
                          width: 220,
                          child: GradientButton(
                            text: 'Explore home',
                            onPressed: () {
                              // Navigate back to home tab
                              // This assumes the parent widget handles tab switching
                              Navigator.of(context).popUntil((route) => route.isFirst);
                            },
                          ),
                        ),
                      ),
                    ],
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