import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import '../../../core/services/biometric_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/deep_linking_service.dart';
import '../../../core/services/deep_link_router.dart';
import '../../../core/constants/app_colors.dart';
import '../services/auth_service.dart';
import 'login_view.dart';
import '../../home/views/tenant_home_view.dart';
import '../../home/views/agent_home_view.dart';

class BiometricLoginView extends StatefulWidget {
  const BiometricLoginView({super.key});

  @override
  State<BiometricLoginView> createState() => _BiometricLoginViewState();
}

class _BiometricLoginViewState extends State<BiometricLoginView> {
  final BiometricService _biometricService = BiometricService();
  final AuthService _authService = AuthService();
  final StorageService _storageService = StorageService();
  
  bool _isLoading = false;
  bool _isBiometricAvailable = false;
  List<BiometricType> _availableBiometrics = [];
  String _biometricTypeName = 'Biometric';

  @override
  void initState() {
    super.initState();
    _checkBiometricAvailability();
  }

  Future<void> _checkBiometricAvailability() async {
    final isAvailable = await _biometricService.isBiometricAvailable();
    final availableBiometrics = await _biometricService.getAvailableBiometrics();
    
    setState(() {
      _isBiometricAvailable = isAvailable;
      _availableBiometrics = availableBiometrics;
      _biometricTypeName = _biometricService.getBiometricTypeDisplayName(availableBiometrics);
    });
  }

  Future<void> _authenticateWithBiometric() async {
    if (!_isBiometricAvailable) {
      _showErrorDialog('Biometric authentication is not available on this device.');
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
        // Navigate to home screen
        _navigateToHome();
      } else {
        _showErrorDialog('Authentication failed. Please try again.');
      }
    } catch (e) {
      _showErrorDialog('Authentication failed. Please try again.');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _navigateToHome() async {
    final userType = await _storageService.getUserType();

    // Consume any pending deep link before navigating
    final pendingDeepLink = DeepLinkingService().getPendingDeepLinkData();
    final pendingPropertyId = pendingDeepLink?['propertyId']?.toString();
    if (pendingPropertyId != null) DeepLinkingService().clearPendingDeepLinkData();

    if (mounted) {
      final homeWidget = (userType != null && userType != 'home_seeker')
          ? const AgentHomeView()
          : const TenantHomeView();

      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => homeWidget),
        (route) => false,
      );

      if (pendingPropertyId != null && pendingPropertyId.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          DeepLinkRouter().navigateToProperty(
            context: DeepLinkRouter().navigatorKey.currentContext,
            propertyId: pendingPropertyId,
          );
        });
      }
    }
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Authentication Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Future<void> _logoutAndGoToLogin() async {
    await _authService.clearUserData();
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const LoginView(),
        ),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            children: [
              const Spacer(),
              
              // Logo
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(20),
                  color: AppColors.primary600.withValues(alpha: 0.1),
                ),
                child: Image.asset(
                  'assets/icons/Layer_x0020_1.png',
                  fit: BoxFit.contain,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Title
              Text(
                'Welcome Back!',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary600,
                ),
              ),
              
              const SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Use $_biometricTypeName to sign in to your account',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              
              const SizedBox(height: 48),
              
              // Biometric Icon
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.primary600.withValues(alpha: 0.1),
                ),
                child: Icon(
                  _availableBiometrics.contains(BiometricType.fingerprint)
                      ? Icons.fingerprint
                      : _availableBiometrics.contains(BiometricType.face)
                          ? Icons.face
                          : Icons.security,
                  size: 40,
                  color: AppColors.primary600,
                ),
              ),
              
              const SizedBox(height: 32),
              
              // Authenticate Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _authenticateWithBiometric,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary600,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : Text(
                          'Authenticate with $_biometricTypeName',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Alternative Options
              TextButton(
                onPressed: _logoutAndGoToLogin,
                child: Text(
                  'Sign in with password instead',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ),
              
              const Spacer(),
              
              // Footer
              Text(
                'PropLinq',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[400],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
