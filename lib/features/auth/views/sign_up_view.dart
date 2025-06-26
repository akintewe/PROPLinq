import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import 'package:proplinq/core/constants/app_typography.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/phone_number_field.dart';
import '../../../core/widgets/location_autocomplete_field.dart';
import '../models/register_request.dart';
import '../services/auth_service.dart';
import 'login_view.dart';
import 'email_verification_view.dart';
import '../../home/views/tenant_home_view.dart';
import '../../home/views/agent_home_view.dart';

class SignUpView extends StatefulWidget {
  const SignUpView({super.key});

  @override
  State<SignUpView> createState() => _SignUpViewState();
}

class _SignUpViewState extends State<SignUpView> {
  bool _isHomeSeeker = true; // Toggle between Home Seeker and Agents
  bool _agreeToTerms = false;
  bool _isLoading = false;
  
  final AuthService _authService = AuthService();
  
  // Google Places API Key
  final String _googleApiKey = 'AIzaSyA5U_6NbBxgiO3P4zNRmDK9SwbEnEPZgJM';
  
  // Controllers for Home Seeker
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneNumberController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  // Additional controllers for Agents
  final TextEditingController _agencyNameController = TextEditingController();
  final TextEditingController _whatsappNumberController = TextEditingController();
  
  // Focus nodes
  final FocusNode _focusNodeFullName = FocusNode();
  final FocusNode _focusNodeAgencyName = FocusNode();
  final FocusNode _focusNodePhoneNumber = FocusNode();
  final FocusNode _focusNodeWhatsappNumber = FocusNode();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodeLocation = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  final FocusNode _focusNodeConfirmPassword = FocusNode();
  
  String _selectedAgentType = 'Select';

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneNumberController.dispose();
    _emailController.dispose();
    _locationController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _agencyNameController.dispose();
    _whatsappNumberController.dispose();
    
    _focusNodeFullName.dispose();
    _focusNodeAgencyName.dispose();
    _focusNodePhoneNumber.dispose();
    _focusNodeWhatsappNumber.dispose();
    _focusNodeEmail.dispose();
    _focusNodeLocation.dispose();
    _focusNodePassword.dispose();
    _focusNodeConfirmPassword.dispose();
    super.dispose();
  }

  void _signUp() async {
    // Validate form
    if (!_validateForm()) {
      return;
    }
    
    setState(() {
      _isLoading = true;
    });

    try {
      // Create registration request
      final registerRequest = RegisterRequest(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        passwordConfirmation: _confirmPasswordController.text,
        userType: _isHomeSeeker ? 'home_seeker' : 'agent',
        phoneNumber: _phoneNumberController.text.trim(),
        location: _locationController.text.trim(),
        termsAccepted: _agreeToTerms,
        agencyName: !_isHomeSeeker ? _agencyNameController.text.trim() : null,
        agentType: !_isHomeSeeker && _selectedAgentType != 'Select' 
            ? _selectedAgentType.toLowerCase().replaceAll(' ', '_') 
            : null,
        whatsappNumber: !_isHomeSeeker ? _whatsappNumberController.text.trim() : null,
      );

      print('🔄 Making registration request...');
      print('📝 Registration Data:');
      print('  - Full Name: ${registerRequest.fullName}');
      print('  - Email: ${registerRequest.email}');
      print('  - User Type: ${registerRequest.userType}');
      print('  - Phone: ${registerRequest.phoneNumber}');
      print('  - Location: ${registerRequest.location}');
      print('  - Terms Accepted: ${registerRequest.termsAccepted}');
      if (!_isHomeSeeker) {
        print('  - Agency Name: ${registerRequest.agencyName}');
        print('  - Agent Type: ${registerRequest.agentType}');
        print('  - WhatsApp: ${registerRequest.whatsappNumber}');
      }

      // Make API call
      final response = await _authService.register(registerRequest);

      print('📋 Registration Response:');
      print('✅ Success: ${response.success}');
      print('📄 Status Code: ${response.statusCode}');
      print('💬 Message: ${response.message}');
      print('🔍 Raw Response Data: ${response.data?.toJson()}');
      
      if (response.data != null) {
        print('👤 User Data:');
        print('  - ID: ${response.data!.user.id}');
        print('  - Name: ${response.data!.user.fullName}');
        print('  - Email: ${response.data!.user.email}');
        print('  - User Type: "${response.data!.user.userType}"');
        print('  - Location: ${response.data!.user.location}');
        print('  - Agency Name: ${response.data!.user.agencyName}');
        print('  - Agent Type: ${response.data!.user.agentType}');
        print('🔑 Token: ${response.data!.token}');
        print('🕒 Token Type: ${response.data!.tokenType}');
      }
      
      if (response.errors != null && response.errors!.isNotEmpty) {
        print('❌ Errors: ${response.errors}');
      }

      if (response.success && response.data != null) {
        // Registration successful - navigate to login
        _showSuccessMessage('Registration successful! Please log in with your credentials.');
        _navigateToLogin();
      } else {
        // Registration failed
        _showErrorMessage(response.message ?? 'Registration failed. Please try again.');
        if (response.errors != null && response.errors!.isNotEmpty) {
          _showErrorMessage(response.errors!.join('\n'));
        }
      }
    } catch (e) {
      _showErrorMessage('An unexpected error occurred. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  bool _validateForm() {
    if (_fullNameController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your full name');
      return false;
    }

    if (_emailController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your email address');
      return false;
    }

    if (!_isValidEmail(_emailController.text.trim())) {
      _showErrorMessage('Please enter a valid email address');
      return false;
    }

    if (_phoneNumberController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your phone number');
      return false;
    }

    if (_locationController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your location');
      return false;
    }

    if (_passwordController.text.isEmpty) {
      _showErrorMessage('Please enter a password');
      return false;
    }

    if (_passwordController.text.length < 8) {
      _showErrorMessage('Password must be at least 8 characters long');
      return false;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      _showErrorMessage('Passwords do not match');
      return false;
    }

    // Agent-specific validations
    if (!_isHomeSeeker) {
      if (_agencyNameController.text.trim().isEmpty) {
        _showErrorMessage('Please enter your agency name');
        return false;
      }

      if (_selectedAgentType == 'Select') {
        _showErrorMessage('Please select your agent type');
        return false;
      }

      if (_whatsappNumberController.text.trim().isEmpty) {
        _showErrorMessage('Please enter your WhatsApp number');
        return false;
      }
    }

    if (!_agreeToTerms) {
      _showErrorMessage('Please agree to Terms and Conditions');
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

  void _navigateToHome() {
    // Navigate based on user type selection (temporary logic)
    if (_isHomeSeeker) {
      // Navigate to tenant home
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TenantHomeView(),
        ),
      );
    } else {
      // Navigate to agent home
      Navigator.of(context).pushReplacement(
      MaterialPageRoute(
          builder: (context) => const AgentHomeView(),
        ),
      );
    }
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sign up successful! Welcome ${_isHomeSeeker ? 'Home Seeker' : 'Agent'}!'),
      ),
    );
  }

  void _continueWithGoogle() {
    // For demo purposes, navigate to appropriate home based on current selection
    if (_isHomeSeeker) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TenantHomeView(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AgentHomeView(),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Continue with Google - Welcome ${_isHomeSeeker ? 'Home Seeker' : 'Agent'}!')),
    );
  }

  void _continueWithApple() {
    // For demo purposes, navigate to appropriate home based on current selection
    if (_isHomeSeeker) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const TenantHomeView(),
        ),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (context) => const AgentHomeView(),
        ),
      );
    }
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Continue with Apple - Welcome ${_isHomeSeeker ? 'Home Seeker' : 'Agent'}!')),
    );
  }

  void _navigateToLogin() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (context) => const LoginView()),
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Title and subtitle
              const Center(
                child: Text(
                  'Sign Up',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  _isHomeSeeker 
                      ? 'Find verified homes, explore tours, and contact agents.'
                      : 'Open an account as an Agent, Company or Realtor.',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF868686),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Toggle buttons
              Center(
                child: Container(
                  width: 240,
                  height: 44,
                  padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                  decoration: BoxDecoration(
                    color: const Color(0xFFECF0F9),
                    borderRadius: BorderRadius.circular(300),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isHomeSeeker = true;
                            });
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: _isHomeSeeker 
                                  ? const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF426DC2),
                                        Color(0xFF63ADDC),
                                        Color(0xFF75CFEA),
                                      ],
                                      stops: [0.0, 1.0, 1.0],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(300),
                            ),
                            child: Center(
                              child: Text(
                                'Home Seeker',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: _isHomeSeeker ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: () {
                            setState(() {
                              _isHomeSeeker = false;
                            });
                          },
                          child: Container(
                            height: 32,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            decoration: BoxDecoration(
                              gradient: !_isHomeSeeker 
                                  ? const LinearGradient(
                                      begin: Alignment.centerLeft,
                                      end: Alignment.centerRight,
                                      colors: [
                                        Color(0xFF426DC2),
                                        Color(0xFF63ADDC),
                                        Color(0xFF75CFEA),
                                      ],
                                      stops: [0.0, 1.0, 1.0],
                                    )
                                  : null,
                              borderRadius: BorderRadius.circular(300),
                            ),
                            child: Center(
                              child: Text(
                                'Agents',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: !_isHomeSeeker ? Colors.white : Colors.black,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Form container
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: const Color(0xFFFAFAFA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Form fields
                    CustomTextField(
                      label: 'Full Name',
                      hintText: 'John Doe',
                      controller: _fullNameController,
                      focusNode: _focusNodeFullName,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Agent-specific fields
                    if (!_isHomeSeeker) ...[
                      CustomTextField(
                        label: 'Agency Name',
                        hintText: 'Enter your agency name',
                        controller: _agencyNameController,
                        focusNode: _focusNodeAgencyName,
                      ),
                      
                      const SizedBox(height: 20),
                      
                      // Dropdown for agent type
                      const Text(
                        'Individual agent, Realtor, Hotel or Apartment',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(30),
                          border: Border.all(
                            color: const Color(0xFFECF0F9),
                            width: 1,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            isExpanded: true,
                            value: _selectedAgentType,
                            items: [
                              'Select',
                              'Individual Agent',
                              'Realtor',
                              'Hotel',
                              'Apartment',
                            ].map((String value) {
                              return DropdownMenuItem<String>(
                                value: value,
                                child: Text(
                                  value,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w400,
                                    color: value == 'Select' 
                                        ? const Color(0xFF868686) 
                                        : Colors.black,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _selectedAgentType = newValue!;
                              });
                            },
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                    
                    PhoneNumberField(
                      label: 'Phone Number',
                      hintText: '8012345678',
                      controller: _phoneNumberController,
                      focusNode: _focusNodePhoneNumber,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // WhatsApp number for agents only
                    if (!_isHomeSeeker) ...[
                      PhoneNumberField(
                        label: 'Whatsapp Number',
                        hintText: '8012345678',
                        controller: _whatsappNumberController,
                        focusNode: _focusNodeWhatsappNumber,
                      ),
                      
                      const SizedBox(height: 20),
                    ],
                    
                    CustomTextField(
                      label: 'Email',
                      hintText: 'Enter your email address',
                      controller: _emailController,
                      focusNode: _focusNodeEmail,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    LocationAutocompleteField(
                      label: 'Location',
                      hintText: 'Enter your location',
                      controller: _locationController,
                      focusNode: _focusNodeLocation,
                      apiKey: _googleApiKey,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    CustomTextField(
                      label: 'Password',
                      hintText: '****************',
                      controller: _passwordController,
                      focusNode: _focusNodePassword,
                      showVisibilityToggle: true,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    CustomTextField(
                      label: 'Confirm Password',
                      hintText: '****************',
                      controller: _confirmPasswordController,
                      focusNode: _focusNodeConfirmPassword,
                      showVisibilityToggle: true,
                    ),
                    
                    const SizedBox(height: 20),
                    
                    // Terms and conditions checkbox
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 20,
                          height: 20,
                          child: Checkbox(
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            side: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                            value: _agreeToTerms,
                            onChanged: (bool? value) {
                              setState(() {
                                _agreeToTerms = value ?? false;
                              });
                            },
                            activeColor: const Color(0xFF426DC2),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: RichText(
                            text: const TextSpan(
                              children: [
                                TextSpan(
                                  text: 'By checking this box, you confirm that you have read, understood, and agree to PropLinQ ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.black,
                                  ),
                                ),
                                TextSpan(
                                  text: 'Terms and Conditions',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0E4CDD),
                                  ),
                                ),
                                TextSpan(
                                  text: ' and ',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Color(0xFF868686),
                                  ),
                                ),
                                TextSpan(
                                  text: 'Privacy Policy',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: Color(0xFF0E4CDD),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 24),
                    
                    // Sign up button
                    GradientButton(
                      text: _isLoading ? 'Signing up...' : 'Sign up',
                      onPressed: _isLoading ? null : _signUp,
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
                    
                    const SizedBox(height: 24),
                    
                    // Login link
                    Center(
                      child: GestureDetector(
                        onTap: _navigateToLogin,
                        child: RichText(
                          text: const TextSpan(
                            children: [
                              TextSpan(
                                text: 'Already have an account? ',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                  color: Color(0xFF868686),
                                ),
                              ),
                              TextSpan(
                                text: 'Log in',
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
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 