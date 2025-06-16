import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:dotted_border/dotted_border.dart';
import 'package:file_picker/file_picker.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/gradient_button.dart';
import 'kyc_success_view.dart';

class CompleteKycView extends StatefulWidget {
  const CompleteKycView({super.key});

  @override
  State<CompleteKycView> createState() => _CompleteKycViewState();
}

class _CompleteKycViewState extends State<CompleteKycView> {
  int _currentStep = 0;
  final int _totalSteps = 3;

  // Controllers for Step 1
  final TextEditingController _fullNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();

  // Controllers for Step 2
  final TextEditingController _occupationController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  String _employmentStatus = '';

  // File upload state
  PlatformFile? _bankStatementFile;
  PlatformFile? _utilityBillFile;

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _occupationController.dispose();
    _companyController.dispose();
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
              'Verify identity and income to unlock flexible rent payments.',
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
      default:
        return _buildStep1();
    }
  }

  Widget _buildStep1() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CustomTextField(
          label: 'Full Name',
          hintText: 'John Doe',
          controller: _fullNameController,
        ),
        
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'Phone Number',
          hintText: 'Enter your phone number',
          controller: _phoneController,
          keyboardType: TextInputType.phone,
        ),
        
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'Email',
          hintText: 'Enter your email address',
          controller: _emailController,
          keyboardType: TextInputType.emailAddress,
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _nextStep,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep2() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Employment Status Dropdown
        const Text(
          'Employed or Self-employed',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                'Select',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: Color(0xFF868686),
                ),
              ),
              icon: const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF868686),
              ),
              isExpanded: true,
              items: ['Employed', 'Self-employed'].map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      color: Colors.black,
                    ),
                  ),
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
        
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'Occupation',
          hintText: 'Enter occupation',
          controller: _occupationController,
        ),
        
        const SizedBox(height: 24),
        
        CustomTextField(
          label: 'Company or Business name',
          hintText: 'Enter company or business name',
          controller: _companyController,
        ),
        
        const SizedBox(height: 40),
        
        GradientButton(
          text: 'Next',
          onPressed: _nextStep,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStep3() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Bank Statement Upload
        const Text(
          'Kindly upload 3-6 months bank statement',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        _buildFileUploadArea('bank_statement'),
        
        const SizedBox(height: 20),
        
        // Utility Bill Upload
        const Text(
          'Kindly upload your current utility bill',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black,
          ),
        ),
        
        const SizedBox(height: 12),
        
        _buildFileUploadArea('utility_bill'),
        
        const SizedBox(height: 32),
        
        GradientButton(
          text: 'Continue',
          onPressed: _completeKyc,
        ),
        
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildFileUploadArea(String type) {
    PlatformFile? selectedFile = type == 'bank_statement' ? _bankStatementFile : _utilityBillFile;
    bool hasFile = selectedFile != null;

    return GestureDetector(
      onTap: () => _pickFile(type),
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
                Icon(
                  Icons.check_circle,
                  size: 32,
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  selectedFile.name,
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
                  '${(selectedFile.size / 1024 / 1024).toStringAsFixed(1)} MB',
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
                  'JPEG, PNG, PDF, and MP4 formats, up to 50MB',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF666666),
                  ),
                ),
                
                const SizedBox(height: 12),
                
                GestureDetector(
                  onTap: () => _pickFile(type),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Color.fromRGBO(176, 181, 187, 1),
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
                ),
              ],
            ],
          ),
        ),
      ),
    );
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
          if (fileType == 'bank_statement') {
            _bankStatementFile = result.files.first;
          } else if (fileType == 'utility_bill') {
            _utilityBillFile = result.files.first;
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

  void _completeKyc() {
    // Navigate to success screen
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (context) => const KycSuccessView(),
      ),
    );
  }
} 