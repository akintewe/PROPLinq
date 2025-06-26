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
      profilePicture: json['profile_picture'],
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
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
} 