import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../auth/services/auth_service.dart';
import '../../home/views/tenant_home_view.dart';
import '../../home/views/agent_home_view.dart';

class VerifyPhoneView extends StatefulWidget {
  final String phoneNumber;
  final bool isHomeSeeker;
  
  const VerifyPhoneView({
    super.key,
    required this.phoneNumber,
    this.isHomeSeeker = true,
  });

  @override
  State<VerifyPhoneView> createState() => _VerifyPhoneViewState();
}

class _VerifyPhoneViewState extends State<VerifyPhoneView> {
  final AuthService _authService = AuthService();
  final TextEditingController _otpController = TextEditingController();
  final FocusNode _otpFocusNode = FocusNode();
  bool _isLoading = false;
  bool _isResending = false;
  String? _errorMessage;
  int _resendCountdown = 0;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    _startResendCountdown();
    _otpController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _otpController.dispose();
    _otpFocusNode.dispose();
    _countdownTimer?.cancel();
    super.dispose();
  }

  void _startResendCountdown() {
    _resendCountdown = 60; // 60 seconds countdown
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_resendCountdown > 0) {
        setState(() {
          _resendCountdown--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  Future<void> _verifyOtp() async {
    if (_otpController.text.trim().isEmpty) {
      setState(() {
        _errorMessage = 'Please enter the OTP code';
      });
      return;
    }

    if (_otpController.text.trim().length != 6) {
      setState(() {
        _errorMessage = 'OTP must be 6 digits';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.verifyOtp(
        otp: _otpController.text.trim(),
      );

      if (!mounted) return;

      if (response.success) {
        // Verification successful - navigate to home
        _navigateToHome();
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Invalid OTP. Please try again.';
          _isLoading = false;
        });
        
        if (response.errors != null && response.errors!.isNotEmpty) {
          setState(() {
            _errorMessage = response.errors!.join('\n');
          });
        }
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resendOtp() async {
    if (_resendCountdown > 0) {
      return; // Don't allow resend during countdown
    }

    setState(() {
      _isResending = true;
      _errorMessage = null;
    });

    try {
      final response = await _authService.resendOtp();

      if (!mounted) return;

      if (response.success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('OTP resent successfully! Please check your phone.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
        _startResendCountdown(); // Restart countdown
      } else {
        setState(() {
          _errorMessage = response.message ?? 'Failed to resend OTP. Please try again.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'An error occurred. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _isResending = false;
        });
      }
    }
  }

  void _navigateToHome() {
    if (widget.isHomeSeeker) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const TenantHomeView(),
        ),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (context) => const AgentHomeView(),
        ),
        (route) => false,
      );
    }
  }

  String _formatPhoneNumber(String phoneNumber) {
    // Format phone number for display: 2348012345678 -> +234 801 234 5678
    if (phoneNumber.startsWith('234')) {
      final number = phoneNumber.substring(3);
      if (number.length >= 10) {
        return '+234 ${number.substring(0, 3)} ${number.substring(3, 6)} ${number.substring(6)}';
      }
      return '+234 $number';
    }
    return phoneNumber;
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
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),
              
              // Title
              const Text(
                'Verify Your Phone Number',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: Colors.black,
                ),
              ),
              
              const SizedBox(height: 12),
              
              // Description
              Text(
                'We\'ve sent a 6-digit verification code to\n${_formatPhoneNumber(widget.phoneNumber)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF666666),
                  height: 1.5,
                ),
              ),
              
              const SizedBox(height: 40),
              
              // OTP Input Field
              CustomTextField(
                label: 'Enter Verification Code',
                hintText: '123456',
                controller: _otpController,
                focusNode: _otpFocusNode,
                keyboardType: TextInputType.number,
                maxLength: 6,
              ),
              
              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.red[700],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              
              const SizedBox(height: 32),
              
              // Verify Button
              GradientButton(
                text: 'Verify Phone Number',
                onPressed: _isLoading ? null : _verifyOtp,
                isEnabled: !_isLoading && _otpController.text.trim().length == 6,
              ),
              
              const SizedBox(height: 24),
              
              // Resend OTP Section
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Didn\'t receive the code?',
                      style: TextStyle(
                        fontSize: 14,
                        color: Color(0xFF666666),
                      ),
                    ),
                    const SizedBox(height: 8),
                    if (_resendCountdown > 0)
                      Text(
                        'Resend code in ${_resendCountdown}s',
                        style: const TextStyle(
                          fontSize: 14,
                          color: Color(0xFF999999),
                          fontWeight: FontWeight.w500,
                        ),
                      )
                    else
                      TextButton(
                        onPressed: _isResending ? null : _resendOtp,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFF426DC2),
                                ),
                              )
                            : const Text(
                                'Resend Code',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFF426DC2),
                                ),
                              ),
                      ),
                  ],
                ),
              ),
              
              const SizedBox(height: 40),
              
              // Info box
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
                        'Check your SMS messages. The code expires in 10 minutes.',
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
            ],
          ),
        ),
      ),
    );
  }
}
