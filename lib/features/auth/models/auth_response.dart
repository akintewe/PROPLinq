import 'user_model.dart';

class AuthResponse {
  final UserModel user;
  final String token;
  final String? tokenType;
  final bool? kycStatus;
  final DateTime? expiresAt;

  AuthResponse({
    required this.user,
    required this.token,
    this.tokenType,
    this.kycStatus,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    // Extract kyc_status from root level and merge with user data
    final userData = Map<String, dynamic>.from(json['user'] ?? {});
    if (json.containsKey('kyc_status')) {
      userData['kyc_status'] = json['kyc_status'];
    }
    
    return AuthResponse(
      user: UserModel.fromJson(userData),
      token: json['token'] ?? '',
      tokenType: json['token_type'],
      kycStatus: json['kyc_status'],
      expiresAt: json['expires_at'] != null 
          ? DateTime.tryParse(json['expires_at']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'token_type': tokenType,
      'kyc_status': kycStatus,
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
} 