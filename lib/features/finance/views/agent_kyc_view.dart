import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import '../../../features/auth/services/auth_service.dart';
import '../../../features/auth/models/agent_kyc_request.dart';
import 'kyc_success_view.dart';

class AgentKycView extends StatefulWidget {
  const AgentKycView({super.key});

  @override
  State<AgentKycView> createState() => _AgentKycViewState();
}

class _AgentKycViewState extends State<AgentKycView> {
  int _currentStep = 0;
  final int _totalSteps = 5; // Back to 5 steps

  // Controllers for Step 1
  final TextEditingController _businessNameController = TextEditingController();
  final TextEditingController _tinController = TextEditingController();

  // Controllers for Step 2
  final TextEditingController _bvnController = TextEditingController();
  final TextEditingController _ninController = TextEditingController();

  // Controllers for Step 3
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _companyNameController = TextEditingController();
  String _employmentStatus = '';

  // File upload state for Step 4
  PlatformFile? _cacDocumentFile;
  PlatformFile? _utilityBillFile;
  PlatformFile? _bankStatementFile;

  // Loading state
  bool _isSubmitting = false;

  final AuthService _authService = AuthService();

  @override
  void initState() {
    super.initState();
    // Add listeners to text controllers to update button state
    _businessNameController.addListener(() => setState(() {}));
    _tinController.addListener(() => setState(() {}));
    _bvnController.addListener(() => setState(() {}));
    _ninController.addListener(() => setState(() {}));
    _occupationController.addListener(() => setState(() {}));
    _companyNameController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _tinController.dispose();
    _bvnController.dispose();
    _ninController.dispose();
    _occupationController.dispose();
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
          } else if (fileType == 'utility') {
            _utilityBillFile = result.files.first;
          } else if (fileType == 'bank') {
            _bankStatementFile = result.files.first;
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
    if (!_validateForm()) {
      return;
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Convert PlatformFile to File
      final cacFile = File(_cacDocumentFile!.path!);
      final utilityFile = File(_utilityBillFile!.path!);
      final bankFile = File(_bankStatementFile!.path!);

      final request = AgentKycRequest(
        bvn: _bvnController.text.trim(),
        nin: _ninController.text.trim(),
        utilityBill: utilityFile,
        bankStatement: bankFile,
        businessName: _businessNameController.text.trim(),
        tin: _tinController.text.trim(),
        cacDoc: cacFile,
        employmentStatus: _employmentStatus,
        occupation: _occupationController.text.trim(),
        companyName: _companyNameController.text.trim(),
      );

      final response = await _authService.submitAgentKyc(request);

      if (response.success) {
        _nextStep(); // Move to success step
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response.message ?? 'Failed to submit KYC'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error submitting KYC: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  bool _validateForm() {
    if (_businessNameController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your business name');
      return false;
    }

    if (_tinController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your TIN');
      return false;
    }

    if (_bvnController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your BVN');
      return false;
    }

    if (_bvnController.text.trim().length != 11) {
      _showErrorMessage('BVN must be 11 digits');
      return false;
    }

    if (_ninController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your NIN');
      return false;
    }

    if (_ninController.text.trim().length != 11) {
      _showErrorMessage('NIN must be 11 digits');
      return false;
    }

    if (_occupationController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your occupation');
      return false;
    }

    if (_companyNameController.text.trim().isEmpty) {
      _showErrorMessage('Please enter your company name');
      return false;
    }

    if (_employmentStatus.isEmpty) {
      _showErrorMessage('Please select your employment status');
      return false;
    }

    if (_cacDocumentFile == null) {
      _showErrorMessage('Please upload your CAC document');
      return false;
    }

    if (_utilityBillFile == null) {
      _showErrorMessage('Please upload your utility bill');
      return false;
    }

    if (_bankStatementFile == null) {
      _showErrorMessage('Please upload your bank statement');
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
      case 2:
        return _buildStep3();
      case 3:
        return _buildStep4();
      case 4:
        return _buildStep5();
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Business Name
        CustomTextField(
          label: 'Business Name',
          hintText: 'Enter your business name',
          controller: _businessNameController,
        ),
        
        const SizedBox(height: 24),
        
        // TIN
        CustomTextField(
          label: 'TIN',
          hintText: 'Enter your TIN',
          controller: _tinController,
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _businessNameController.text.isNotEmpty && 
                    _tinController.text.isNotEmpty ? _nextStep : null,
          isEnabled: _businessNameController.text.isNotEmpty && 
                     _tinController.text.isNotEmpty,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // BVN
        CustomTextField(
          label: 'BVN',
          hintText: 'Enter your 11-digit BVN',
          controller: _bvnController,
          keyboardType: TextInputType.number,
          maxLength: 11,
          onChanged: (_) => setState(() {}),
        ),
        
        const SizedBox(height: 24),
        
        // NIN
        CustomTextField(
          label: 'NIN',
          hintText: 'Enter your 11-digit NIN',
          controller: _ninController,
          keyboardType: TextInputType.number,
          maxLength: 11,
          onChanged: (_) => setState(() {}),
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _bvnController.text.length == 11 && 
                    _ninController.text.length == 11 ? _nextStep : null,
          isEnabled: _bvnController.text.length == 11 && 
                     _ninController.text.length == 11,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Occupation
        CustomTextField(
          label: 'Occupation',
          hintText: 'Enter your occupation',
          controller: _occupationController,
          onChanged: (_) => setState(() {}),
        ),
        
        const SizedBox(height: 24),
        
        // Company Name
        CustomTextField(
          label: 'Company Name',
          hintText: 'Enter your company name',
          controller: _companyNameController,
          onChanged: (_) => setState(() {}),
        ),
        
        const SizedBox(height: 24),
        
        // Employment Status
        const Text(
          'Employment Status',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Employment Status Dropdown
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
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
              value: _employmentStatus.isEmpty ? null : _employmentStatus,
              hint: const Text(
                'Select employment status',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF868686),
                ),
              ),
              isExpanded: true,
              items: [
                'employed',
                'self_employed',
                'unemployed',
                'student',
                'retired',
              ].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(value.replaceAll('_', ' ').toUpperCase()),
                );
              }).toList(),
              onChanged: (String? newValue) {
                setState(() {
                  _employmentStatus = newValue ?? '';
                });
              },
            ),
          ),
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _occupationController.text.isNotEmpty && 
                    _companyNameController.text.isNotEmpty && 
                    _employmentStatus.isNotEmpty ? _nextStep : null,
          isEnabled: _occupationController.text.isNotEmpty && 
                     _companyNameController.text.isNotEmpty && 
                     _employmentStatus.isNotEmpty,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep4() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // CAC Document Upload
        const Text(
          'Kindly upload your CAC document',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildFileUploadArea(
          fileType: 'cac',
          file: _cacDocumentFile,
          onTap: () => _pickFile('cac'),
        ),
        
        const SizedBox(height: 32),
        
        // Utility Bill Upload
        const Text(
          'Kindly upload your current utility bill',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildFileUploadArea(
          fileType: 'utility',
          file: _utilityBillFile,
          onTap: () => _pickFile('utility'),
        ),
        
        const SizedBox(height: 32),
        
        // Bank Statement Upload
        const Text(
          'Kindly upload your bank statement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 16),
        
        _buildFileUploadArea(
          fileType: 'bank',
          file: _bankStatementFile,
          onTap: () => _pickFile('bank'),
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _cacDocumentFile != null && 
                    _utilityBillFile != null && 
                    _bankStatementFile != null ? _nextStep : null,
          isEnabled: _cacDocumentFile != null && 
                     _utilityBillFile != null && 
                     _bankStatementFile != null,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep5() {
    return Column(
      children: [
        const SizedBox(height: 40),
        
        // Review section
        const Text(
          'Review Your Information',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: Colors.black,
          ),
          textAlign: TextAlign.center,
        ),
        
        const SizedBox(height: 20),
        
        // Review details
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildReviewItem('Business Name', _businessNameController.text),
              _buildReviewItem('TIN', _tinController.text),
              _buildReviewItem('BVN', _bvnController.text),
              _buildReviewItem('NIN', _ninController.text),
              _buildReviewItem('Occupation', _occupationController.text),
              _buildReviewItem('Company Name', _companyNameController.text),
              _buildReviewItem('Employment Status', _employmentStatus.replaceAll('_', ' ').toUpperCase()),
              _buildReviewItem('Documents', 'CAC, Utility Bill, Bank Statement'),
            ],
          ),
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: _isSubmitting ? 'Submitting...' : 'Submit KYC',
          onPressed: !_isSubmitting ? _submitKyc : null,
          isEnabled: !_isSubmitting,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildReviewItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black,
              ),
            ),
          ),
        ],
      ),
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