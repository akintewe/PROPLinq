import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/gradient_button.dart';

class KycDialog extends StatelessWidget {
  final VoidCallback? onGetStarted;
  final VoidCallback? onRemindLater;

  const KycDialog({
    super.key,
    this.onGetStarted,
    this.onRemindLater,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        width: 343,
        height: 408,
        padding: const EdgeInsets.fromLTRB(15, 20, 15, 20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Illustration
            Container(
              width: double.infinity,
              height: 120,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF5F7FA),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: SvgPicture.asset(
                  'assets/icons/Completed Task 1.svg',
                  width: 88,
                  height: 88,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    // Fallback illustration if SVG fails to load
                    return Container(
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        color: const Color(0xFF426DC2),
                        borderRadius: BorderRadius.circular(44),
                      ),
                      child: const Icon(
                        Icons.verified_user,
                        size: 44,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
            
            const SizedBox(height: 27),
            
            // Title
            const Text(
              'Complete Your KYC to Get Verified',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.black,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 12),
            
            // Description
            const Text(
              'Build trust with buyers and stand out on PROPLINQ by completing your KYC (Know Your Customer) verification.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w400,
                color: Color(0xFF868686),
                height: 1.3,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 27),
            
            // Get Started Button
            GradientButton(
              text: 'Get Started',
              onPressed: () {
                Navigator.of(context).pop();
                onGetStarted?.call();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Remind me Later Button
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                onRemindLater?.call();
              },
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 8),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              child: const Text(
                'Remind me Later',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Color(0xFF426DC2),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  static void show(
    BuildContext context, {
    VoidCallback? onGetStarted,
    VoidCallback? onRemindLater,
  }) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => KycDialog(
        onGetStarted: onGetStarted,
        onRemindLater: onRemindLater,
      ),
    );
  }
} 