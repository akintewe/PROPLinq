class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String userType;
  final String phoneNumber;
  final String location;
  final String? agencyName;
  final String? agentType;
  final String? whatsappNumber;
  final bool? emailVerified;
  final String? profilePicture;
  final DateTime? emailVerifiedAt;
  final DateTime? phoneVerifiedAt;
  final bool? kycStatus;
  final Map<String, dynamic>? kycData;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  UserModel({
    required this.id,
    required this.fullName,
    required this.email,
    required this.userType,
    required this.phoneNumber,
    required this.location,
    this.agencyName,
    this.agentType,
    this.whatsappNumber,
    this.emailVerified,
    this.profilePicture,
    this.emailVerifiedAt,
    this.phoneVerifiedAt,
    this.kycStatus,
    this.kycData,
    this.createdAt,
    this.updatedAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Debug: Print the raw JSON to see the actual structure
    print('🔵 [UserModel] Raw JSON response: $json');
    print('🔵 [UserModel] Checking for user type fields:');
    print('  - json["role"]: ${json["role"]}');
    print('  - json["user_type"]: ${json["user_type"]}');
    print('  - json["userType"]: ${json["userType"]}');
    
    // Try multiple field names for user type
    final userType = json['role'] ?? 
                     json['user_type'] ?? 
                     json['userType'] ?? 
                     '';
    
    print('🔵 [UserModel] Final userType: "$userType"');
    
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      userType: userType,
      phoneNumber: json['phone_number'] ?? '',
      location: json['location'] ?? '',
      agencyName: json['agency_name'],
      agentType: json['agent_type'],
      whatsappNumber: json['whatsapp_number'],
      emailVerified: json['email_verified'],
      profilePicture: json['profile_image_url'] ?? json['profile_picture'],
      emailVerifiedAt: json['email_verified_at'] != null 
          ? DateTime.tryParse(json['email_verified_at']) 
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null 
          ? DateTime.tryParse(json['phone_verified_at']) 
          : null,
      kycStatus: json['kyc_status'] is bool
          ? json['kyc_status']
          : (json['kyc'] != null ? true : null),
      kycData: json['kyc'] is Map<String, dynamic> ? json['kyc'] : null,
      createdAt: json['created_at'] != null 
          ? DateTime.tryParse(json['created_at']) 
          : null,
      updatedAt: json['updated_at'] != null 
          ? DateTime.tryParse(json['updated_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'user_type': userType,
      'phone_number': phoneNumber,
      'location': location,
      'agency_name': agencyName,
      'agent_type': agentType,
      'whatsapp_number': whatsappNumber,
      'email_verified': emailVerified,
      'profile_picture': profilePicture,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'kyc_status': kycStatus,
      'kyc': kycData,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Get verification status badge text based on KYC data
  String get verificationStatus {
    // Check if kycData contains status information
    if (kycData != null && kycData!['status'] != null) {
      final status = kycData!['status'].toString().toLowerCase();
      if (status == 'approved' || status == 'verified') {
        return 'Verified';
      } else if (status == 'pending') {
        return 'Pending';
      } else if (status == 'rejected') {
        return 'Rejected';
      }
    }

    // Fallback to kycStatus boolean field
    if (kycStatus == true) {
      return 'Verified';
    } else if (kycStatus == false) {
      return 'Unverified';
    }

    // Default
    return 'Unverified';
  }
} 