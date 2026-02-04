import 'dart:io';

class AgentKycRequest {
  final String? nin; // Optional - removed from UI
  final String? bvn; // Optional - removed from UI
  final String? tin; // Optional - either BVN or TIN required
  final String companyName; // Required
  final File cacDoc; // Required
  final String? businessName; // Optional
  final String? employmentStatus; // Optional
  final String? occupation; // Optional
  final File? utilityBill; // Optional
  final File? bankStatement; // Optional

  AgentKycRequest({
    this.nin,
    this.bvn,
    this.tin,
    required this.companyName,
    required this.cacDoc,
    this.businessName,
    this.employmentStatus,
    this.occupation,
    this.utilityBill,
    this.bankStatement,
  });

  // Convert to form data fields (text fields)
  Map<String, String> toFormFields() {
    print('🔵 [AGENT KYC] Creating form fields...');
    print('🔵 [AGENT KYC] Raw values:');
    print('  - nin: "${nin ?? 'NULL'}"');
    print('  - bvn: "${bvn ?? 'NULL'}"');
    print('  - tin: "${tin ?? 'NULL'}"');
    print('  - companyName: "$companyName"');
    print('  - businessName: "${businessName ?? 'NULL'}"');
    print('  - employmentStatus: "${employmentStatus ?? 'NULL'}"');
    print('  - occupation: "${occupation ?? 'NULL'}"');
    
    final fields = <String, String>{
      'company_name': companyName,
    };

    // Add NIN if provided
    if (nin != null && nin!.isNotEmpty) {
      fields['nin'] = nin!;
      print('  ✅ Added NIN: "${nin!}"');
    } else {
      print('  ⚠️ NIN not provided');
    }

    // Add BVN if provided
    if (bvn != null && bvn!.isNotEmpty) {
      fields['bvn'] = bvn!;
      print('  ✅ Added BVN: "${bvn!}"');
    } else {
      print('  ⚠️ BVN not provided');
    }

    // Add TIN if provided
    if (tin != null && tin!.isNotEmpty) {
      fields['tin'] = tin!;
      print('  ✅ Added TIN: "${tin!}"');
    } else {
      print('  ⚠️ TIN not provided');
    }

    // Business name is REQUIRED by API - use businessName if provided, otherwise use companyName
    if (businessName != null && businessName!.isNotEmpty) {
      fields['business_name'] = businessName!;
      print('  ✅ Added business_name: "${businessName!}" (explicitly provided)');
    } else {
      // API requires business_name, so use company_name as fallback
      fields['business_name'] = companyName;
      print('  ✅ Added business_name: "$companyName" (using company_name as fallback)');
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

    print('🔵 [AGENT KYC] Final form fields: $fields');
    return fields;
  }

  // Convert to form data files
  Map<String, File> toFormFiles() {
    print('🔵 [AGENT KYC] Creating form files...');
    final files = <String, File>{
      'cac_doc': cacDoc,
    };
    print('  ✅ Added cac_doc: ${cacDoc.path}');

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

    print('🔵 [AGENT KYC] Total files: ${files.length}');
    return files;
  }
} 