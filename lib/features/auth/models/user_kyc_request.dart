import 'dart:io';

class UserKycRequest {
  final String nin; // Required for home seekers
  final String? bvn; // Optional
  final File? utilityBill; // Optional
  final File? bankStatement; // Optional
  final String? employmentStatus; // Optional
  final String? occupation; // Optional
  final String? companyName; // Optional
  final String? tin; // Optional
  final File? cacDoc; // Optional
  final String? businessName; // Optional

  UserKycRequest({
    required this.nin,
    this.bvn,
    this.utilityBill,
    this.bankStatement,
    this.employmentStatus,
    this.occupation,
    this.companyName,
    this.tin,
    this.cacDoc,
    this.businessName,
  });

  // Convert to form data fields (text fields)
  Map<String, String> toFormFields() {
    print('🟢 [USER KYC] Creating form fields...');
    print('🟢 [USER KYC] Raw values:');
    print('  - nin: "$nin"');
    print('  - bvn: "${bvn ?? 'NULL'}"');
    print('  - employmentStatus: "${employmentStatus ?? 'NULL'}"');
    print('  - occupation: "${occupation ?? 'NULL'}"');
    print('  - companyName: "${companyName ?? 'NULL'}"');
    print('  - tin: "${tin ?? 'NULL'}"');
    print('  - businessName: "${businessName ?? 'NULL'}"');
    
    final fields = <String, String>{
      'nin': nin,
    };

    // Add optional fields only if provided and not empty
    if (bvn != null && bvn!.isNotEmpty) {
      fields['bvn'] = bvn!;
      print('  ✅ Added bvn: "${bvn!}"');
    } else {
      print('  ⚠️ bvn not provided');
    }
    if (employmentStatus != null && employmentStatus!.isNotEmpty) {
      fields['employment_status'] = employmentStatus!;
      print('  ✅ Added employment_status: "${employmentStatus!}"');
    } else {
      print('  ⚠️ employment_status not provided');
    }
    if (occupation != null && occupation!.isNotEmpty) {
      fields['occupation'] = occupation!;
      print('  ✅ Added occupation: "${occupation!}"');
    } else {
      print('  ⚠️ occupation not provided');
    }
    if (companyName != null && companyName!.isNotEmpty) {
      fields['company_name'] = companyName!;
      print('  ✅ Added company_name: "${companyName!}"');
    } else {
      print('  ⚠️ company_name not provided');
    }
    if (tin != null && tin!.isNotEmpty) {
      fields['tin'] = tin!;
      print('  ✅ Added tin: "${tin!}"');
    } else {
      print('  ⚠️ tin not provided');
    }
    if (businessName != null && businessName!.isNotEmpty) {
      fields['business_name'] = businessName!;
      print('  ✅ Added business_name: "${businessName!}"');
    } else {
      print('  ⚠️ business_name not provided');
    }

    print('🟢 [USER KYC] Final form fields: $fields');
    return fields;
  }

  // Convert to form data files
  Map<String, File> toFormFiles() {
    print('🟢 [USER KYC] Creating form files...');
    final files = <String, File>{};

    // Add optional files only if provided
    if (utilityBill != null) {
      files['utility_bill'] = utilityBill!;
      print('  ✅ Added utility_bill: ${utilityBill!.path}');
    } else {
      print('  ⚠️ utility_bill not provided');
    }
    if (bankStatement != null) {
      files['bank_statement'] = bankStatement!;
      print('  ✅ Added bank_statement: ${bankStatement!.path}');
    } else {
      print('  ⚠️ bank_statement not provided');
    }
    if (cacDoc != null) {
      files['cac_doc'] = cacDoc!;
      print('  ✅ Added cac_doc: ${cacDoc!.path}');
    } else {
      print('  ⚠️ cac_doc not provided');
    }

    print('🟢 [USER KYC] Total files: ${files.length}');
    return files;
  }
} 