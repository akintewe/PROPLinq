import 'user_model.dart';

class AuthResponse {
  final UserModel user;
  final String token;
  final String? tokenType;
  final DateTime? expiresAt;

  AuthResponse({
    required this.user,
    required this.token,
    this.tokenType,
    this.expiresAt,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserModel.fromJson(json['user'] ?? {}),
      token: json['token'] ?? '',
      tokenType: json['token_type'],
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
      'expires_at': expiresAt?.toIso8601String(),
    };
  }
} 