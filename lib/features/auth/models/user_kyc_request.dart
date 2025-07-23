import 'dart:io';

class UserKycRequest {
  final String bvn;
  final String nin;
  final File utilityBill;
  final File bankStatement;
  final String employmentStatus;
  final String occupation;
  final String companyName;
  final String tin;
  final File? cacDoc;
  final String? businessName;

  UserKycRequest({
    required this.bvn,
    required this.nin,
    required this.utilityBill,
    required this.bankStatement,
    required this.employmentStatus,
    required this.occupation,
    required this.companyName,
    required this.tin,
    this.cacDoc,
    this.businessName,
  });

  // Convert to form data fields (text fields)
  Map<String, String> toFormFields() {
    final fields = {
      'bvn': bvn,
      'nin': nin,
      'employment_status': employmentStatus,
      'occupation': occupation,
      'company_name': companyName,
      'tin': tin,
    };

    // Add optional fields if provided
    if (businessName != null && businessName!.isNotEmpty) {
      fields['business_name'] = businessName!;
    }

    return fields;
  }

  // Convert to form data files
  Map<String, File> toFormFiles() {
    final files = {
      'utility_bill': utilityBill,
      'bank_statement': bankStatement,
    };

    // Add optional CAC document if provided
    if (cacDoc != null) {
      files['cac_doc'] = cacDoc!;
    }

    return files;
  }
} 