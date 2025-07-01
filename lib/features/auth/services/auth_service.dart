import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../models/auth_response.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../models/kyc_status_response.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final ApiService _apiService = ApiService();
  final StorageService _storageService = StorageService();

  // Register user
  Future<ApiResponse<AuthResponse>> register(RegisterRequest request) async {
    final response = await _apiService.post<AuthResponse>(
      ApiConstants.register,
      body: request.toJson(),
      fromJson: (json) => AuthResponse.fromJson(json),
    );

    // Save token and user data if registration successful
    if (response.success && response.data != null) {
      await _storageService.saveToken(response.data!.token);
      await _storageService.saveUserData(response.data!.user.toJson());
      await _storageService.saveUserType(response.data!.user.userType);
    }

    return response;
  }

  // Login user
  Future<ApiResponse<AuthResponse>> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiService.post<AuthResponse>(
      ApiConstants.login,
      body: {
        'email': email,
        'password': password,
      },
      fromJson: (json) => AuthResponse.fromJson(json),
    );

    // Save token and user data if login successful
    if (response.success && response.data != null) {
      await _storageService.saveToken(response.data!.token);
      await _storageService.saveUserData(response.data!.user.toJson());
      await _storageService.saveUserType(response.data!.user.userType);
    }

    return response;
  }

  // Logout user
  Future<ApiResponse<Map<String, dynamic>>> logout() async {
    final response = await _apiService.post<Map<String, dynamic>>(
      ApiConstants.logout,
      requiresAuth: true,
      fromJson: (json) => json,
    );

    // Clear local storage regardless of API response
    await _storageService.clearAll();

    return response;
  }

  // Forgot password
  Future<ApiResponse<Map<String, dynamic>>> forgotPassword({
    required String email,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.forgotPassword,
      body: {
        'email': email,
      },
      fromJson: (json) => json,
    );
  }

  // Reset password
  Future<ApiResponse<Map<String, dynamic>>> resetPassword({
    required String email,
    required String token,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.resetPassword,
      body: {
        'email': email,
        'token': token,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      fromJson: (json) => json,
    );
  }

  // Verify email
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail({
    required String email,
    required String token,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.verifyEmail,
      body: {
        'email': email,
        'token': token,
      },
      fromJson: (json) => json,
    );
  }

  // Resend email verification
  Future<ApiResponse<Map<String, dynamic>>> resendEmailVerification({
    required String email,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.resendVerification,
      body: {
        'email': email,
      },
      fromJson: (json) => json,
    );
  }

  // Get current user profile
  Future<ApiResponse<UserModel>> getProfile() async {
    return await _apiService.get<UserModel>(
      ApiConstants.profile,
      requiresAuth: true,
      fromJson: (json) => UserModel.fromJson(json),
    );
  }

  // Update user profile
  Future<ApiResponse<UserModel>> updateProfile({
    required Map<String, dynamic> userData,
  }) async {
    final response = await _apiService.put<UserModel>(
      ApiConstants.updateProfile,
      body: userData,
      requiresAuth: true,
      fromJson: (json) => UserModel.fromJson(json),
    );

    // Update local user data if successful
    if (response.success && response.data != null) {
      await _storageService.saveUserData(response.data!.toJson());
    }

    return response;
  }

  // Change password
  Future<ApiResponse<Map<String, dynamic>>> changePassword({
    required String currentPassword,
    required String newPassword,
    required String newPasswordConfirmation,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.changePassword,
      body: {
        'current_password': currentPassword,
        'new_password': newPassword,
        'new_password_confirmation': newPasswordConfirmation,
      },
      requiresAuth: true,
      fromJson: (json) => json,
    );
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    return await _storageService.isLoggedIn();
  }

  // Get current user data from storage
  Future<UserModel?> getCurrentUser() async {
    final userData = await _storageService.getUserData();
    if (userData != null) {
      return UserModel.fromJson(userData);
    }
    return null;
  }

  // Get user type from storage
  Future<String?> getUserType() async {
    return await _storageService.getUserType();
  }

  // Get KYC status
  Future<ApiResponse<KycStatusResponse>> getKycStatus() async {
    return await _apiService.get<KycStatusResponse>(
      ApiConstants.kycStatus,
      requiresAuth: true,
      fromJson: (json) => KycStatusResponse.fromJson(json),
    );
  }

  // Clear all user data (local logout)
  Future<void> clearUserData() async {
    await _storageService.clearAll();
  }
} 