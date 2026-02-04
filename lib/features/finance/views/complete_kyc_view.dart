import 'package:flutter/material.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../auth/services/auth_service.dart';
import '../../auth/models/user_kyc_request.dart';
import 'kyc_success_view.dart';

class CompleteKycView extends StatefulWidget {
  const CompleteKycView({super.key});

  @override
  State<CompleteKycView> createState() => _CompleteKycViewState();
}

class _CompleteKycViewState extends State<CompleteKycView> {
  int _currentStep = 0;
  final int _totalSteps = 1; // Simplified to 1 step - only NIN required
  final AuthService _authService = AuthService();

  // Controller for NIN (only required field)
  final TextEditingController _ninController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Add listener to update button state when text changes
    _ninController.addListener(() {
      setState(() {}); // Rebuild to enable/disable submit button
    });
  }

  @override
  void dispose() {
    _ninController.dispose();
    super.dispose();
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // Header with back button and close button
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: _currentStep > 0 ? _previousStep : () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back,
                        size: 20,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.of(context).pop(),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.grey.withOpacity(0.3),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.close,
                        size: 20,
                        color: Color(0xFF426DC2),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: _buildProgressBar(),
            ),

            const SizedBox(height: 32),

            // Title and subtitle
            const Text(
              'Complete KYC',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            
            const SizedBox(height: 12),
            
            const Text(
              'Enter your NIN to verify your identity.',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: Color(0xFF666666),
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            
            const SizedBox(height: 40),

            // Content based on current step
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: _buildStepContent(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    double progressValue = (_currentStep + 1) / _totalSteps;
    
    return Container(
      width: double.infinity,
      height: 9,
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(40),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: progressValue,
          child: Container(
            height: 9,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [
                  Color(0xFF426DC2),
                  Color(0xFF63ADDC),
                  Color(0xFF75CFEA),
                ],
              ),
              borderRadius: BorderRadius.circular(40),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStepContent() {
    return _buildNinStep();
  }

  Widget _buildNinStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'NIN (National Identification Number)',
          hintText: 'Enter your 11-digit NIN',
          controller: _ninController,
          keyboardType: TextInputType.number,
          maxLength: 11,
        ),
        
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: const Color(0xFFE0E0E0),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              const Icon(
                Icons.info_outline,
                size: 20,
                color: Color(0xFF426DC2),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Your NIN is required to verify your identity. This information is kept secure and confidential.',
                    style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                    height: 1.4,
                    ),
                  ),
                ),
              ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Submit',
          onPressed: _ninController.text.length == 11 ? _completeKyc : null,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Future<void> _completeKyc() async {
    // Validate NIN
    if (_ninController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your NIN'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_ninController.text.trim().length != 11) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('NIN must be 11 digits'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    print('🟢🟢🟢 [USER KYC VIEW] ========================================');
    print('🟢 [USER KYC VIEW] Starting homeseeker KYC submission...');
    print('🟢 [USER KYC VIEW] NIN: "${_ninController.text.trim()}"');

    // Show loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );

    try {
      // Create UserKycRequest with only NIN (all other fields optional)
      print('🟢 [USER KYC VIEW] Creating UserKycRequest...');
      final request = UserKycRequest(
        nin: _ninController.text.trim(),
        // All other fields are optional for home seekers
      );

      print('🟢 [USER KYC VIEW] Calling auth service...');
      // Submit KYC
      final response = await _authService.submitUserKyc(request);

      // Hide loading indicator
      Navigator.of(context).pop();

      if (response.success) {
        print('✅ [USER KYC VIEW] KYC submission successful!');
        // Navigate to success screen
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const KycSuccessView(),
          ),
        );
      } else {
        print('🔴 [USER KYC VIEW] KYC submission failed');
        print('🔴 [USER KYC VIEW] Error message: ${response.message}');
        print('🔴 [USER KYC VIEW] Errors: ${response.errors}');
        
        // Build error message from all validation errors
        String errorMessage = response.message ?? 'Failed to submit KYC';
        
        // If there are multiple validation errors, show them all
        if (response.errors != null && response.errors!.isNotEmpty) {
          if (response.errors is List) {
            // Handle array of error messages
            final errorList = response.errors as List;
            if (errorList.length > 1) {
              errorMessage = 'Please fix the following errors:\n' + 
                           errorList.map((e) => '• $e').join('\n');
            } else if (errorList.isNotEmpty) {
              errorMessage = errorList.first.toString();
            }
          } else if (response.errors is Map) {
            // Handle map of field errors
            final errorMap = response.errors as Map;
            final allErrors = <String>[];
            errorMap.forEach((key, value) {
              if (value is List && value.isNotEmpty) {
                allErrors.addAll(value.map((e) => e.toString()));
              } else {
                allErrors.add(value.toString());
              }
            });
            if (allErrors.length > 1) {
              errorMessage = 'Please fix the following errors:\n' + 
                           allErrors.map((e) => '• $e').join('\n');
            } else if (allErrors.isNotEmpty) {
              errorMessage = allErrors.first;
            }
          }
        }
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 5), // Show longer for multiple errors
            behavior: SnackBarBehavior.floating,
            action: SnackBarAction(
              label: 'Dismiss',
              textColor: Colors.white,
              onPressed: () {
                ScaffoldMessenger.of(context).hideCurrentSnackBar();
              },
            ),
          ),
        );
      }
    } catch (e, stackTrace) {
      print('🔴 [USER KYC VIEW] Exception caught: $e');
      print('🔴 [USER KYC VIEW] Stack trace: $stackTrace');
      
      // Hide loading indicator
      Navigator.of(context).pop();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while submitting your KYC. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    }
    print('🟢🟢🟢 [USER KYC VIEW] ========================================');
  }
} 