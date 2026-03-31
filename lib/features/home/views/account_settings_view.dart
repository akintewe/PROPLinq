import 'package:flutter/material.dart';
import 'package:proplinq/core/constants/app_colors.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_model.dart';
import '../../finance/views/complete_kyc_view.dart';
import '../../finance/views/agent_kyc_view.dart';

class AccountSettingsView extends StatefulWidget {
  const AccountSettingsView({super.key});

  @override
  State<AccountSettingsView> createState() => _AccountSettingsViewState();
}

class _AccountSettingsViewState extends State<AccountSettingsView> {
  final AuthService _authService = AuthService();
  UserModel? _currentUser;
  bool _isLoading = true;
  bool _isRequestingVerification = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
  }

  Future<void> _fetchUserProfile() async {
    try {
      final response = await _authService.getProfile();
      
      if (response.success && response.data != null) {
        setState(() {
          _currentUser = response.data;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        _showMessage('Failed to load profile: ${response.message}');
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      _showMessage('Error loading profile: $e');
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _showVerificationCodeDialog({
    required String title,
    required String subtitle,
    required Function(String) onVerify,
  }) {
    final codeController = TextEditingController();
    bool isVerifying = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(title),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                subtitle,
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: codeController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                decoration: const InputDecoration(
                  labelText: 'Enter verification code',
                  hintText: '123456',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: isVerifying ? null : () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: isVerifying ? null : () async {
                if (codeController.text.trim().length != 6) {
                  _showMessage('Please enter a 6-digit code');
                  return;
                }

                setDialogState(() {
                  isVerifying = true;
                });

                try {
                  await onVerify(codeController.text.trim());
                  Navigator.pop(context);
                  await _fetchUserProfile(); // Refresh profile to update verification status
                } catch (e) {
                  setDialogState(() {
                    isVerifying = false;
                  });
                }
              },
              child: isVerifying 
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Verify'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _requestPhoneVerification() async {
    setState(() {
      _isRequestingVerification = true;
    });

    try {
      final response = await _authService.requestPhoneVerification();
      
      if (response.success) {
        _showMessage('Verification code sent to your phone');
        _showVerificationCodeDialog(
          title: 'Verify Phone Number',
          subtitle: 'Enter the 6-digit code sent to ${_currentUser?.phoneNumber}',
          onVerify: (code) async {
            final verifyResponse = await _authService.verifyPhone(code);
            if (verifyResponse.success) {
              _showMessage('Phone number verified successfully!');
            } else {
              _showMessage('Verification failed: ${verifyResponse.message}');
              throw Exception(verifyResponse.message);
            }
          },
        );
      } else {
        _showMessage('Failed to send verification code: ${response.message}');
      }
    } catch (e) {
      _showMessage('Error requesting verification: $e');
    } finally {
      setState(() {
        _isRequestingVerification = false;
      });
    }
  }

  Future<void> _requestEmailVerification() async {
    setState(() {
      _isRequestingVerification = true;
    });

    try {
      final response = await _authService.requestNewEmailVerification();
      
      if (response.success) {
        _showMessage('Verification code sent to your email');
        _showVerificationCodeDialog(
          title: 'Verify Email Address',
          subtitle: 'Enter the 6-digit code sent to ${_currentUser?.email}',
          onVerify: (code) async {
            final verifyResponse = await _authService.verifyNewEmail(code);
            if (verifyResponse.success) {
              _showMessage('Email address verified successfully!');
            } else {
              _showMessage('Verification failed: ${verifyResponse.message}');
              throw Exception(verifyResponse.message);
            }
          },
        );
      } else {
        _showMessage('Failed to send verification code: ${response.message}');
      }
    } catch (e) {
      _showMessage('Error requesting verification: $e');
    } finally {
      setState(() {
        _isRequestingVerification = false;
      });
    }
  }

  String _getKycStatusText() {
    if (_currentUser?.kycStatus == true) {
      return 'Identity verified';
    } else if (_currentUser?.kycData != null) {
      return 'Verification in progress';
    } else {
      return 'Identity verification required';
    }
  }

  void _navigateToKycScreen() {
    if (_currentUser?.userType != 'home_seeker') {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const AgentKycView(),
        ),
      );
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const CompleteKycView(),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Account Settings',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black,
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _currentUser == null
              ? const Center(child: Text('Failed to load user data'))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Status',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Email Verification
                      _buildVerificationItem(
                        icon: Icons.email_outlined,
                        title: 'Email Address',
                        subtitle: _currentUser!.email,
                        isVerified: _currentUser!.emailVerifiedAt != null,
                        onVerify: _currentUser!.emailVerifiedAt == null 
                            ? _requestEmailVerification 
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Phone Verification
                      _buildVerificationItem(
                        icon: Icons.phone_outlined,
                        title: 'Phone Number',
                        subtitle: _currentUser!.phoneNumber,
                        isVerified: _currentUser!.phoneVerifiedAt != null,
                        onVerify: _currentUser!.phoneVerifiedAt == null 
                            ? _requestPhoneVerification 
                            : null,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // KYC Verification
                      _buildVerificationItem(
                        icon: Icons.verified_user_outlined,
                        title: 'KYC Verification',
                        subtitle: _getKycStatusText(),
                        isVerified: _currentUser!.kycStatus == true,
                        onVerify: _currentUser!.kycStatus != true 
                            ? _navigateToKycScreen 
                            : null,
                      ),
                      
                      const SizedBox(height: 32),
                      
                      // Additional account information
                      const Text(
                        'Account Information',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black,
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      _buildInfoItem(
                        icon: Icons.person_outline,
                        title: 'Full Name',
                        value: _currentUser!.fullName,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoItem(
                        icon: Icons.location_on_outlined,
                        title: 'Location',
                        value: _currentUser!.location,
                      ),
                      
                      const SizedBox(height: 16),
                      
                      _buildInfoItem(
                        icon: Icons.badge_outlined,
                        title: 'Account Type',
                        value: _currentUser!.userType != 'home_seeker' ? 'Agent' : 'Home Seeker',
                      ),

                      // Show agency details for agents
                      if (_currentUser!.userType != 'home_seeker') ...[
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          icon: Icons.business_outlined,
                          title: 'Agency',
                          value: _currentUser!.agencyName ?? 'Not specified',
                        ),
                        
                        const SizedBox(height: 16),
                        _buildInfoItem(
                          icon: Icons.work_outline,
                          title: 'Agent Type',
                          value: _currentUser!.agentType ?? 'Not specified',
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }

  Widget _buildVerificationItem({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isVerified,
    VoidCallback? onVerify,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isVerified ? Colors.green.withOpacity(0.3) : Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isVerified ? Colors.green.withOpacity(0.1) : const Color(0xFF426DC2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: isVerified ? Colors.green : const Color(0xFF426DC2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (isVerified)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Text(
                          'Verified',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                            color: Colors.green,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          if (!isVerified && onVerify != null)
            SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: _isRequestingVerification ? null : onVerify,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF426DC2),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  textStyle: const TextStyle(fontSize: 12),
                ),
                child: _isRequestingVerification
                    ? const SizedBox(
                        width: 12,
                        height: 12,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text('Verify'),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildInfoItem({
    required IconData icon,
    required String title,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.grey50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFF426DC2).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: const Color(0xFF426DC2),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
} 