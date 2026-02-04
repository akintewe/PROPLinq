import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'login_view.dart';

class ResetPasswordView extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordView({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordView> createState() => _ResetPasswordViewState();
}

class _ResetPasswordViewState extends State<ResetPasswordView> {
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _focusNodeNewPassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();
  final AuthService _authService = AuthService();

  bool _isLoading = false;
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

  bool _validateForm() {
    final password = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (password.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please enter your new password';
      });
      _showErrorMessage(_errorMessage);
      return false;
    }

    if (password.length < 8) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Password must be at least 8 characters long';
      });
      _showErrorMessage(_errorMessage);
      return false;
    }

    // Check for uppercase, lowercase, and number
    if (!RegExp(r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$').hasMatch(password)) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Password must contain uppercase, lowercase, and numbers';
      });
      _showErrorMessage(_errorMessage);
      return false;
    }

    if (confirmPassword.isEmpty) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Please confirm your password';
      });
      _showErrorMessage(_errorMessage);
      return false;
    }

    if (password != confirmPassword) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Passwords do not match';
      });
      _showErrorMessage(_errorMessage);
      return false;
    }

    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  Future<void> _resetPassword() async {
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      final response = await _authService.resetPasswordWithOtp(
        email: widget.email,
        otp: widget.otp,
        password: _newPasswordController.text,
        passwordConfirmation: _confirmPasswordController.text,
      );

      if (!mounted) return;

      if (response.success) {
        _showSuccessMessage('Password reset successfully!');

        // Wait 2 seconds then navigate to login
        await Future.delayed(const Duration(seconds: 2));

        if (!mounted) return;

        // Navigate to login screen and clear the stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const LoginView()),
          (route) => false,
        );
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = response.message ?? 'Failed to reset password. Please try again.';
        });
        _showErrorMessage(_errorMessage);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _hasError = true;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      _showErrorMessage(_errorMessage);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
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
                  'Your new password must be different from your previous password',
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
                hasError: _hasError,
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

              const SizedBox(height: 24),

              // Info box about password requirements
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF426DC2).withOpacity(0.2),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.info_outline,
                      color: Color(0xFF426DC2),
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Password must be at least 8 characters long with uppercase, lowercase, and numbers.',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey[700],
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // Reset button
              GradientButton(
                text: _isLoading ? 'Resetting...' : 'Reset Password',
                onPressed: _isLoading ? null : _resetPassword,
              ),

              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
