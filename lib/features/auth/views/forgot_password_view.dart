import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'enter_code_view.dart';

class ForgotPasswordView extends StatefulWidget {
  const ForgotPasswordView({super.key});

  @override
  State<ForgotPasswordView> createState() => _ForgotPasswordViewState();
}

class _ForgotPasswordViewState extends State<ForgotPasswordView> {
  final TextEditingController _emailController = TextEditingController();
  final FocusNode _focusNodeEmail = FocusNode();

  @override
  void dispose() {
    _emailController.dispose();
    _focusNodeEmail.dispose();
    super.dispose();
  }

  void _sendEmail() {
    // Handle send email logic
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const EnterCodeView()),
    );
  }

  void _goBack() {
    Navigator.of(context).pop();
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Title and subtitle
              const Center(
                child: Text(
                  'Forgot Password?',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              const Center(
                child: Text(
                  'Enter your email below, and a link will be sent to you to reset it.',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF868686),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Email field
              CustomTextField(
                label: 'Email',
                hintText: 'Enter your email address',
                controller: _emailController,
                focusNode: _focusNodeEmail,
                keyboardType: TextInputType.emailAddress,
              ),
              
              const SizedBox(height: 32),
              
              // Send Email button
              GradientButton(
                text: 'Send Email',
                onPressed: _sendEmail,
              ),
              
              const SizedBox(height: 24),
              
              // Back link
              Center(
                child: GestureDetector(
                  onTap: _goBack,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(
                        Icons.arrow_back,
                        color: Color(0xFF426DC2),
                        size: 16,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Back',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Color(0xFF426DC2),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
} 