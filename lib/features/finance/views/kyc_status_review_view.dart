import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../../core/widgets/gradient_button.dart';

class KycStatusReviewView extends StatelessWidget {
  final String? statusMessage;
  
  const KycStatusReviewView({
    super.key, 
    this.statusMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              // Close button
              Align(
                alignment: Alignment.topRight,
                child: GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.grey.withOpacity(0.3),
                        width: 1.5,
                      ),
                    ),
                    child: const Icon(
                      Icons.close,
                      size: 20,
                      color: Color(0xFF426DC2),
                    ),
                  ),
                ),
              ),

              // Spacer to center content
              const Spacer(flex: 2),

              // Review illustration
              SizedBox(
                width: 200,
                height: 200,
                child: SvgPicture.asset(
                  'assets/icons/Frame 124.svg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      width: 200,
                      height: 200,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2).withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          // Background circles
                          Positioned(
                            top: 40,
                            left: 20,
                            child: Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF426DC2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            top: 60,
                            right: 30,
                            child: Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF75CFEA),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 50,
                            left: 30,
                            child: Container(
                              width: 4,
                              height: 4,
                              decoration: BoxDecoration(
                                color: const Color(0xFF63ADDC),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 40,
                            right: 20,
                            child: Container(
                              width: 10,
                              height: 10,
                              decoration: const BoxDecoration(
                                color: Color(0xFF426DC2),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                          // Clock icon instead of checkmark
                          Container(
                            width: 80,
                            height: 80,
                            decoration: const BoxDecoration(
                              color: Color(0xFF426DC2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.schedule,
                              size: 40,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 40),

              // Review title
              const Text(
                'We\'re reviewing your KYC',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Review message
              Text(
                statusMessage ?? 'Your KYC verification is being reviewed. We\'ll notify you once the review is complete and your Rent-Now, Pay-Later eligibility is confirmed.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Information card
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFFE9ECEF),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: const BoxDecoration(
                            color: Color(0xFF426DC2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'What happens next?',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.black,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      '• Our team will review your submitted documents\n• Verification typically takes 24-48 hours\n• You\'ll receive a notification once approved\n• Once approved, you can access Rent-Now, Pay-Later features',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),

              // Spacer to push button to bottom
              const Spacer(flex: 3),

              // Go back home button
              GradientButton(
                text: 'Go back home',
                onPressed: () {
                  // Navigate back to home screen
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
} 