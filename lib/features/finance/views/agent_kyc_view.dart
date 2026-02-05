import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/auth/models/agent_kyc_request.dart';
import 'agent_kyc_success_view.dart';

class AgentKycView extends StatefulWidget {
  const AgentKycView({super.key});

  @override
  State<AgentKycView> createState() => _AgentKycViewState();
}

class _AgentKycViewState extends State<AgentKycView> {
  int _currentStep = 0;
  final int _totalSteps = 2; // 2 steps: Required Info, Documents

  // Controllers
  final TextEditingController _ninController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();

  // File upload state
  PlatformFile? _cacDocumentFile;

  // Loading state
  bool _isSubmitting = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to update button state
    _ninController.addListener(() => setState(() {}));
    _companyNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _ninController.dispose();
    _companyNameController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_currentStep < _totalSteps - 1) {
      setState(() {
        _currentStep++;
      });
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      setState(() {
        _currentStep--;
      });
    }
  }

  Future<void> _pickFile(String fileType) async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        setState(() {
          if (fileType == 'cac') {
            _cacDocumentFile = result.files.first;
          }
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.files.first.name} selected successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking file: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _submitKyc() async {
    print('🔵🔵🔵 [AGENT KYC VIEW] ========================================');
    print('🔵 [AGENT KYC VIEW] Starting KYC submission...');
    
    if (!_validateForm()) {
      print('🔴 [AGENT KYC VIEW] Form validation failed');
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert PlatformFile to File
      final cacFile = File(_cacDocumentFile!.path!);
      
      print('🔵 [AGENT KYC VIEW] Creating AgentKycRequest with:');
      print('  - NIN: "${_ninController.text.trim().isNotEmpty ? _ninController.text.trim() : 'EMPTY'}"');
      print('  - Company Name: "${_companyNameController.text.trim()}"');
      print('  - CAC Doc: ${cacFile.path}');

      final request = AgentKycRequest(
        nin: _ninController.text.trim().isNotEmpty ? _ninController.text.trim() : null,
        bvn: null, // BVN removed from UI
        tin: null, // TIN removed from UI
        companyName: _companyNameController.text.trim(),
        cacDoc: cacFile,
        // All other fields are optional
      );

      print('🔵 [AGENT KYC VIEW] Calling auth service...');
      final response = await _authService.submitAgentKyc(request);

      if (response.success) {
        print('✅ [AGENT KYC VIEW] KYC submission successful!');
        // Navigate to agent KYC success view
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => const AgentKycSuccessView(),
          ),
        );
      } else {
        print('🔴 [AGENT KYC VIEW] KYC submission failed');
        print('🔴 [AGENT KYC VIEW] Error message: ${response.message}');
        print('🔴 [AGENT KYC VIEW] Errors: ${response.errors}');
        
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
      print('🔴 [AGENT KYC VIEW] Exception caught: $e');
      print('🔴 [AGENT KYC VIEW] Stack trace: $stackTrace');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('An error occurred while submitting your KYC. Please try again.'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
      print('🔵🔵🔵 [AGENT KYC VIEW] ========================================');
    }
  }

  bool _validateForm() {
    // Company Name is required
    if (_companyNameController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your company name');
      return false;
    }

    // CAC Document is required
    if (_cacDocumentFile == null) {
      _showErrorMessage('Please upload your CAC document');
      return false;
    }

    return true;
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
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
              'Verify identity to unlock unlimited posting of properties',
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
    switch (_currentStep) {
      case 0:
        return _buildStep1();
      case 1:
        return _buildStep2();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // NIN (Required)
        CustomTextField(
          label: 'NIN (National Identification Number)',
          hintText: 'Enter your NIN',
          controller: _ninController,
          keyboardType: TextInputType.number,
        ),
        
        const SizedBox(height: 24),
        
        // Company Name (Required)
        CustomTextField(
          label: 'Company Name',
          hintText: 'Enter your company name',
          controller: _companyNameController,
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _companyNameController.text.isNotEmpty ? _nextStep : null,
          isEnabled: _companyNameController.text.isNotEmpty,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CAC Document Upload (Required)
        const Text(
          'CAC Document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 8),
        
        const Text(
          'Kindly upload your CAC (Corporate Affairs Commission) document',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: Color(0xFF666666),
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildFileUploadArea(
          fileType: 'cac',
          file: _cacDocumentFile,
          onTap: () => _pickFile('cac'),
        ),
        
        const SizedBox(height: 32),
        
        GradientButton(
          text: _isSubmitting ? 'Submitting...' : 'Submit KYC',
          onPressed: !_isSubmitting && _cacDocumentFile != null ? _submitKyc : null,
          isEnabled: !_isSubmitting && _cacDocumentFile != null,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }




  Widget _buildFileUploadArea({
    required String fileType,
    required PlatformFile? file,
    required VoidCallback onTap,
  }) {
    bool hasFile = file != null;
    
    return GestureDetector(
      onTap: onTap,
      child: DottedBorder(
        color: hasFile ? const Color(0xFF426DC2) : const Color(0xFFD0D0D0),
        strokeWidth: 1.5,
        dashPattern: const [6, 3],
        borderType: BorderType.RRect,
        radius: const Radius.circular(12),
        child: Container(
          width: double.infinity,
          height: 160,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (hasFile) ...[
                const Icon(
                  Icons.check_circle,
                  size: 32,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  file.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.black,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  '${(file.size / 1024 / 1024).toStringAsFixed(1)} MB',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF426DC2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Change File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ] else ...[
                SvgPicture.asset(
                  'assets/icons/cloud-add.svg',
                  width: 20,
                  height: 20,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.cloud_upload,
                      size: 20,
                      color: Color(0xFF666666),
                    );
                  },
                ),
                
                const SizedBox(height: 12),
                
                const Text(
                  'Choose a file or drag & drop it here',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black,
                  ),
                ),
                
                const SizedBox(height: 4),
                
                const Text(
                  'JPEG, PNG, PDF formats, up to 2MB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color.fromRGBO(176, 181, 187, 1),
                      width: 1,
                    ),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Browse File',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Color.fromRGBO(84, 87, 92, 1),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
} 