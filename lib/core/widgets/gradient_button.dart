import 'package:flutter/material.dart';

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const GradientButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: isEnabled
              ? const LinearGradient(
                  begin: Alignment(-0.99, 0.0), // 91.33 degrees approximation
                  end: Alignment(0.99, 0.0),
                  stops: [0.0113, 0.4555, 1.1245], // 1.13%, 45.55%, 112.45%
                  colors: [
                    Color(0xFF426DC2), // #426DC2
                    Color(0xFF75CFEA), // #75CFEA
                    Color(0xCC33CC99), // rgba(51, 204, 153, 0.8)
                  ],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.shade400,
                    Colors.grey.shade500,
                  ],
                ),
          borderRadius: BorderRadius.circular(100),
        ),
        child: ElevatedButton(
          onPressed: isEnabled ? onPressed : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(100),
            ),
            padding: const EdgeInsets.only(
              top: 10,
              right: 52,
              bottom: 13,
              left: 52,
            ),
          ),
          child: Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ),
    );
  }
} 