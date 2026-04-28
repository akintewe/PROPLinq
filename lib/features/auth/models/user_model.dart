class UserModel {
  final String id;
  final String fullName;
  final String email;
  final String userType;
  final String phoneNumber;
  final String location;
  final String? country; // User's country (detected from IP or manually set)
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
    this.country,
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
    // Unwrap nested 'user' key if backend wraps the object
    if (json.containsKey('user') && json['user'] is Map<String, dynamic>) {
      json = json['user'] as Map<String, dynamic>;
    }

    // Resolve user type from whichever field the backend sends
    final userType = (json['role'] ?? json['user_type'] ?? json['userType'])?.toString() ?? '';

    // kycStatus: accept bool or int (0/1)
    final rawKyc = json['kyc_status'];
    bool? kycStatus;
    if (rawKyc is bool) {
      kycStatus = rawKyc;
    } else if (rawKyc == 1 || rawKyc == '1') {
      kycStatus = true;
    } else if (rawKyc == 0 || rawKyc == '0') {
      kycStatus = false;
    } else if (json['kyc'] != null) {
      kycStatus = true;
    }

    // kycData: only accept if it's actually a Map
    final rawKycData = json['kyc'];
    final kycData = rawKycData is Map ? Map<String, dynamic>.from(rawKycData) : null;

    // emailVerified: accept bool or int
    final rawEv = json['email_verified'];
    bool? emailVerified;
    if (rawEv is bool) {
      emailVerified = rawEv;
    } else if (rawEv != null) {
      emailVerified = rawEv == 1 || rawEv == '1';
    }

    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      userType: userType,
      phoneNumber: json['phone_number']?.toString() ?? '',
      location: json['location']?.toString() ?? '',
      country: json['country']?.toString(),
      agencyName: json['agency_name']?.toString(),
      agentType: json['agent_type']?.toString(),
      whatsappNumber: json['whatsapp_number']?.toString(),
      emailVerified: emailVerified,
      profilePicture: json['profile_image_url']?.toString() ?? json['profile_picture']?.toString(),
      emailVerifiedAt: json['email_verified_at'] != null
          ? DateTime.tryParse(json['email_verified_at'].toString())
          : null,
      phoneVerifiedAt: json['phone_verified_at'] != null
          ? DateTime.tryParse(json['phone_verified_at'].toString())
          : null,
      kycStatus: kycStatus,
      kycData: kycData,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'].toString())
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.tryParse(json['updated_at'].toString())
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
      'country': country,
      'agency_name': agencyName,
      'agent_type': agentType,
      'whatsapp_number': whatsappNumber,
      'email_verified': emailVerified,
      'profile_picture': profilePicture,
      'profile_image_url': profilePicture,
      'email_verified_at': emailVerifiedAt?.toIso8601String(),
      'phone_verified_at': phoneVerifiedAt?.toIso8601String(),
      'kyc_status': kycStatus,
      'kyc': kycData,
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }

  /// Check if user is in Nigeria
  bool get isInNigeria {
    return country?.toLowerCase() == 'nigeria' || country?.toLowerCase() == 'ng';
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