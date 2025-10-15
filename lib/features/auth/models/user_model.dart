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
    return UserModel(
      id: json['id']?.toString() ?? '',
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      userType: json['role'] ?? '', // API uses 'role' instead of 'user_type'
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
      kycStatus: json['kyc_status'] ?? (json['kyc'] != null),
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
} 