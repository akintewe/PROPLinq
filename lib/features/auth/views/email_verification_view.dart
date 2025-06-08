import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';

class EmailVerificationView extends StatelessWidget {
  final String email;
  
  const EmailVerificationView({
    super.key,
    required this.email,
  });

  void _resendEmail(BuildContext context) {
    // Handle resend email logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Verification email sent!')),
    );
  }

  void _didntReceiveIt(BuildContext context) {
    // Handle didn't receive it logic
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Please check your spam folder')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 24.0, top: 8.0, bottom: 8.0, right: 8.0),
          child: GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: SizedBox(
              width: 40,
              height: 40,
              child: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFFEFF0F2),
                    width: 1.14,
                  ),
                ),
                child: const Center(
                  child: Icon(
                    Icons.arrow_back,
                    color: Color(0xFF426DC2),
                    size: 20,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 40),
              
              // Title
              const Text(
                'Email verification',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle with email
              Text(
                'An email has been sent to $email with a verification link. Please check your inbox and click the link to verify your email address.',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF868686),
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 24),
              
              // Didn't receive it link
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => _didntReceiveIt(context),
                  child: const Text(
                    'Didn\'t receive it?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0E4CDD),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Resend Email button
              GradientButton(
                text: 'Resend Email',
                onPressed: () => _resendEmail(context),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
} 