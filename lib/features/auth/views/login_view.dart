import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/auth_service.dart';
import 'forgot_password_view.dart';
import 'sign_up_view.dart';
import '../../home/views/tenant_home_view.dart';
import '../../home/views/agent_home_view.dart';

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  
  bool _isPasswordVisible = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _focusNodeEmail.dispose();
    _focusNodePassword.dispose();
    super.dispose();
  }

  void _signIn() async {
    // Validate form
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      print('🔄 Making login request...');
      print('📧 Email: ${_emailController.text.trim()}');
      print('🔑 Password: [HIDDEN]');
      
      // Make API call
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      print('📋 Login Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      print('🔍 Raw Response Data: ${response.data?.toJson()}');
      
      if (response.data != null) {
        print('👤 User Data:');
        print('  - ID: ${response.data!.user.id}');
        print('  - Name: ${response.data!.user.fullName}');
        print('  - Email: ${response.data!.user.email}');
        print('  - User Type: ${response.data!.user.userType}');
        print('  - Location: ${response.data!.user.location}');
        print('🔑 Token: ${response.data!.token}');
        print('🕒 Token Type: ${response.data!.tokenType}');
      }
      
      if (response.errors != null && response.errors!.isNotEmpty) {
        print('❌ Errors: ${response.errors}');
      }

      if (response.success && response.data != null) {
        // Login successful
        _showSuccessMessage('Login successful! Welcome back, ${response.data!.user.fullName}!');
        _navigateToHome(response.data!.user.userType);
      } else {
        // Login failed
        setState(() {
          _hasError = true;
          _errorMessage = response.message ?? 'Login failed. Please try again.';
        });
        
        if (response.errors != null && response.errors!.isNotEmpty) {
          _showErrorMessage(response.errors!.join('\n'));
        } else {
          _showErrorMessage(response.message ?? 'Login failed. Please try again.');
        }
      }
    } catch (e) {
      print('💥 Login Exception: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'An unexpected error occurred. Please try again.';
      });
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_emailController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your email address');
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address');
      return false;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorMessage('Please enter your password');
      return false;
    }

    return true;
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email);
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

  void _navigateToHome([String? userType]) {
    print('🏠 Navigating to home for user type: $userType');
    
    // Navigate based on user type from API response
    if (userType == 'agent') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AgentHomeView(),
        ),
      );
    } else {
      // Default to tenant home for 'home_seeker' or any other type
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TenantHomeView(),
        ),
      );
    }
  }

  void _continueWithGoogle() {
    // Handle Google sign in
    // For demo purposes, navigate to tenant home (since no email input for social login)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const TenantHomeView(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continue with Google - Navigated to Tenant Home')),
    );
  }

  void _continueWithApple() {
    // Handle Apple sign in
    // For demo purposes, navigate to tenant home (since no email input for social login)
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const TenantHomeView(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Continue with Apple - Navigated to Tenant Home')),
    );
  }

  void _forgotPassword() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const ForgotPasswordView()),
    );
  }

  void _signUp() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const SignUpView()),
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
                  'Log In',
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
                  'Welcome back, let\'s help you find your next home.',
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
              
              const SizedBox(height: 20),
              
              // Password field
              CustomTextField(
                label: 'Password',
                hintText: '****************',
                controller: _passwordController,
                focusNode: _focusNodePassword,
                showVisibilityToggle: true,
                hasError: _hasError,
                errorMessage: _errorMessage,
              ),
              
              const SizedBox(height: 16),
              
              // Forgot password
              Align(
                alignment: Alignment.centerRight,
                child: GestureDetector(
                  onTap: _forgotPassword,
                  child: const Text(
                    'Forgot Password?',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF0E4CDD),
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Sign In button
              GradientButton(
                text: _isLoading ? 'Signing In...' : 'Sign In',
                onPressed: _isLoading ? null : _signIn,
              ),
              
              const SizedBox(height: 24),
              
              // Or divider with lines
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 0.5,
                      color: const Color(0xFFCFD3D6),
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: Text(
                      'Or',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF868686),
                      ),
                    ),
                  ),
                  Expanded(
                    child: Container(
                      height: 0.5,
                      color: const Color(0xFFCFD3D6),
                    ),
                  ),
                ],
              ),
              
              const SizedBox(height: 24),
              
              // Google sign in button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _continueWithGoogle,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECF0F9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 50,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Continue with Google',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/icons/Google svg.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            width: 20,
                            height: 20,
                            decoration: const BoxDecoration(
                              color: Color(0xFF4285F4),
                              shape: BoxShape.circle,
                            ),
                            child: const Center(
                              child: Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Apple sign in button
              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  onPressed: _continueWithApple,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFECF0F9),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(100),
                    ),
                    padding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 50,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Continue with Apple',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w300,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(width: 10),
                      SvgPicture.asset(
                        'assets/icons/Apple svg.svg',
                        width: 20,
                        height: 20,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(
                            Icons.apple,
                            size: 20,
                            color: Colors.black,
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Sign up text
              Center(
                child: GestureDetector(
                  onTap: _signUp,
                  child: RichText(
                    text: const TextSpan(
                      children: [
                        TextSpan(
                          text: 'Don\'t have an account? ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF868686),
                          ),
                        ),
                        TextSpan(
                          text: 'Sign up',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0E4CDD),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
} 