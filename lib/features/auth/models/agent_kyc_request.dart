import 'dart:io';

class AgentKycRequest {
  final String bvn;
  final String nin;
  final File utilityBill;
  final File bankStatement;
  final String businessName;
  final String tin;
  final File cacDoc;
  final String employmentStatus;
  final String occupation;
  final String companyName;

  AgentKycRequest({
    required this.bvn,
    required this.nin,
    required this.utilityBill,
    required this.bankStatement,
    required this.businessName,
    required this.tin,
    required this.cacDoc,
    required this.employmentStatus,
    required this.occupation,
    required this.companyName,
  });

  // Convert to form data fields (text fields)
  Map<String, String> toFormFields() {
    return {
      'bvn': bvn,
      'nin': nin,
      'business_name': businessName,
      'tin': tin,
      'employment_status': employmentStatus,
      'occupation': occupation,
      'company_name': companyName,
    };
  }

  // Convert to form data files
  Map<String, File> toFormFiles() {
    return {
      'utility_bill': utilityBill,
      'bank_statement': bankStatement,
      'cac_doc': cacDoc,
    };
  }
} 