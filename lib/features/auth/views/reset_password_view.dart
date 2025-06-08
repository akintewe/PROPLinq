import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import 'login_view.dart';

class ResetPasswordView extends StatefulWidget {
  const ResetPasswordView({super.key});

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _focusNodeNewPassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();
  
  bool _hasError = false;
  String _errorMessage = '';

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _focusNodeNewPassword.dispose();
    _focusNodeConfirmPassword.dispose();
    super.dispose();
  }

  void _resetPassword() {
    // Handle password reset logic
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Passwords do not match';
      });
      return;
    }
    
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    
    // Navigate to login screen after successful reset
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => const LoginView()),
      (route) => false,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Title and subtitle
              const Center(
                child: Text(
                  'Reset Password',
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
                  'Kindly enter a new password and also confirm new password',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF868686),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // New Password field
              CustomTextField(
                label: 'New Password',
                hintText: '****************',
                controller: _newPasswordController,
                focusNode: _focusNodeNewPassword,
                showVisibilityToggle: true,
              ),
              
              const SizedBox(height: 20),
              
              // Confirm New Password field
              CustomTextField(
                label: 'Confirm New Password',
                hintText: '****************',
                controller: _confirmPasswordController,
                focusNode: _focusNodeConfirmPassword,
                showVisibilityToggle: true,
                hasError: _hasError,
                errorMessage: _errorMessage,
              ),
              
              const SizedBox(height: 32),
              
              // Reset button
              GradientButton(
                text: 'Reset',
                onPressed: _resetPassword,
              ),
              
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
} 