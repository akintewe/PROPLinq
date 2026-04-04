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
    final rawUser = json['user'];
    final userData = rawUser is Map
        ? Map<String, dynamic>.from(rawUser)
        : <String, dynamic>{};
    if (json.containsKey('kyc_status')) {
      userData['kyc_status'] = json['kyc_status'];
    }

    final rawKyc = json['kyc_status'];
    bool? kycStatus;
    if (rawKyc is bool) {
      kycStatus = rawKyc;
    } else if (rawKyc == 1 || rawKyc == '1') {
      kycStatus = true;
    } else if (rawKyc == 0 || rawKyc == '0') {
      kycStatus = false;
    }

    return AuthResponse(
      user: UserModel.fromJson(userData),
      token: json['token']?.toString() ?? '',
      tokenType: json['token_type']?.toString(),
      kycStatus: kycStatus,
      expiresAt: json['expires_at'] != null
          ? DateTime.tryParse(json['expires_at'].toString())
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