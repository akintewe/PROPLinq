import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/onesignal_service.dart';
import '../../../core/services/deep_linking_service.dart';
import '../services/auth_service.dart';
import 'forgot_password_view.dart';
import 'sign_up_view.dart';
import 'biometric_login_view.dart';
import '../../home/views/tenant_home_view.dart';
import '../../home/views/agent_home_view.dart';
import '../../home/views/guest_home_view.dart';

class LoginView extends StatefulWidget {
  /// Called with the login BuildContext after successful login, before navigation.
  /// Use this to push extra routes on top of the home screen.
  final void Function(BuildContext loginContext, String? userType)? onLoginSuccess;

  const LoginView({super.key, this.onLoginSuccess});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final FocusNode _focusNodeEmail = FocusNode();
  final FocusNode _focusNodePassword = FocusNode();
  
  bool _hasError = false;
  String _errorMessage = '';
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  bool _isBiometricEnabled = false;
  bool _rememberMe = false;
  
  final AuthService _authService = AuthService();
  final BiometricService _biometricService = BiometricService();
  final StorageService _storageService = StorageService();
  final OneSignalService _oneSignalService = OneSignalService();

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final isEnabled = await _storageService.isBiometricEnabled();
    
    setState(() {
      _isBiometricAvailable = isAvailable;
      _isBiometricEnabled = isEnabled;
    });
  }

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
      
      // Make API call
      final response = await _authService.login(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      
      if (response.data != null) {
      }
      
      if (response.errors != null && response.errors!.isNotEmpty) {
      }

      if (response.success && response.data != null) {
        // Login successful
        _showSuccessMessage('Login successful! Welcome back, ${response.data!.user.fullName}!');
        
        // Save remember me preference
        await _storageService.setRememberMe(_rememberMe);
        
        // Enable biometric authentication if available
        if (_isBiometricAvailable) {
          await _storageService.setBiometricEnabled(true);
          setState(() {
            _isBiometricEnabled = true;
          });
        }
        
        // Set OneSignal user ID and tags
        await _oneSignalService.setExternalUserId(response.data!.user.id.toString());
        await _oneSignalService.setUserType(response.data!.user.userType);
        if (response.data!.user.location.isNotEmpty) {
          await _oneSignalService.setUserLocation(response.data!.user.location);
        }
        
        // Set AppsFlyer customer user ID for attribution tracking
        DeepLinkingService().setUserId(response.data!.user.id.toString());
        
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
    if (widget.onLoginSuccess != null) {
      widget.onLoginSuccess!(context, userType);
      return;
    }
    if (userType != null && userType != 'home_seeker') {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const AgentHomeView()),
      );
    } else {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const TenantHomeView()),
      );
    }
  }

  Future<void> _continueWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      // On iOS, GIDClientID in Info.plist is used automatically.
      // serverClientId is only needed on Android to request an id_token.
      final googleSignIn = Theme.of(context).platform == TargetPlatform.iOS
          ? GoogleSignIn()
          : GoogleSignIn(
              serverClientId: '1001918940088-ojltopdgg71rkusq50p104tqmg5mdk8n.apps.googleusercontent.com',
            );
      final googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return; // user cancelled
      }
      final googleAuth = await googleUser.authentication;
      final idToken = googleAuth.idToken;
      if (idToken == null) {
        _showErrorMessage('Google sign-in failed. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final response = await _authService.socialLogin(
        provider: 'google',
        body: {'id_token': idToken},
      );

      if (response.success && response.data != null) {
        await _oneSignalService.setExternalUserId(response.data!.user.id.toString());
        await _oneSignalService.setUserType(response.data!.user.userType);
        DeepLinkingService().setUserId(response.data!.user.id.toString());
        _navigateToHome(response.data!.user.userType);
      } else {
        _showErrorMessage(response.message ?? 'Google sign-in failed. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Google sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _continueWithApple() async {
    setState(() => _isLoading = true);
    try {
      final credential = await SignInWithApple.getAppleIDCredential(
        scopes: [
          AppleIDAuthorizationScopes.email,
          AppleIDAuthorizationScopes.fullName,
        ],
      );

      final identityToken = credential.identityToken;
      if (identityToken == null) {
        _showErrorMessage('Apple sign-in failed. Please try again.');
        setState(() => _isLoading = false);
        return;
      }

      final fullName = [
        credential.givenName,
        credential.familyName,
      ].where((n) => n != null && n.isNotEmpty).join(' ');

      final response = await _authService.socialLogin(
        provider: 'apple',
        body: {
          'identity_token': identityToken,
          if (fullName.isNotEmpty) 'full_name': fullName,
        },
      );

      if (response.success && response.data != null) {
        await _oneSignalService.setExternalUserId(response.data!.user.id.toString());
        await _oneSignalService.setUserType(response.data!.user.userType);
        DeepLinkingService().setUserId(response.data!.user.id.toString());
        _navigateToHome(response.data!.user.userType);
      } else {
        _showErrorMessage(response.message ?? 'Apple sign-in failed. Please try again.');
      }
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code != AuthorizationErrorCode.canceled) {
        _showErrorMessage('Apple sign-in failed. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Apple sign-in failed. Please try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
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

  Future<void> _authenticateWithBiometric() async {
    if (!_isBiometricAvailable) {
      _showErrorMessage('Biometric authentication is not available on this device.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final bool authenticated = await _biometricService.authenticate(
        reason: 'Authenticate to access your PropLinq account',
      );

      if (authenticated) {
        // Navigate to biometric login screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const BiometricLoginView(),
          ),
        );
      } else {
        _showErrorMessage('Biometric authentication failed. Please try again.');
      }
    } catch (e) {
      _showErrorMessage('Biometric authentication failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop();
        } else {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const GuestHomeView()),
          );
        }
      },
      child: Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
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
              Expanded(
                child: SingleChildScrollView(
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
              
              // Remember me checkbox and Forgot password
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Remember me checkbox
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        _rememberMe = !_rememberMe;
                      });
                    },
                    child: Row(
                      children: [
                        Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            color: _rememberMe ? const Color(0xFF0E4CDD) : Colors.white,
                            border: Border.all(
                              color: _rememberMe ? const Color(0xFF0E4CDD) : const Color(0xFFCFD3D6),
                              width: 1.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: _rememberMe
                              ? const Icon(
                                  Icons.check,
                                  size: 14,
                                  color: Colors.white,
                                )
                              : null,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Remember me',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: Color(0xFF868686),
                          ),
                        ),
                      ],
                    ),
                  ),
              
              // Forgot password
                  GestureDetector(
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
                ],
              ),
              
              const SizedBox(height: 32),
              
              // Sign In button
              GradientButton(
                text: _isLoading ? 'Signing In...' : 'Sign In',
                onPressed: _isLoading ? null : _signIn,
              ),
              
              const SizedBox(height: 16),
              
              // Biometric login button (only show if biometric is available and enabled)
              if (_isBiometricAvailable && _isBiometricEnabled) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: ElevatedButton.icon(
                    onPressed: _isLoading ? null : _authenticateWithBiometric,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: const Color(0xFF426DC2),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(100),
                        side: const BorderSide(
                          color: Color(0xFF426DC2),
                          width: 1,
                        ),
                      ),
                    ),
                    icon: const Icon(
                      Icons.fingerprint,
                      size: 20,
                    ),
                    label: const Text(
                      'Use Biometric',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ] else
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
              
              // Apple sign in — iOS only
              if (Theme.of(context).platform == TargetPlatform.iOS) ...[
                const SizedBox(height: 16),
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
              ],
              
              const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Sign up text - outside scrollable area
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
    ),
    );
  }
} 