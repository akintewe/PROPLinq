import 'dart:io';
import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/services/api_service.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/bookings_cache_service.dart';
import '../models/auth_response.dart';
import '../models/register_request.dart';
import '../models/user_model.dart';
import '../models/kyc_status_response.dart';
import '../models/agent_kyc_request.dart';
import '../models/user_kyc_request.dart';

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
      
      // Fetch complete profile data to get profile image URL
      try {
        final profileResponse = await getProfile();
        if (profileResponse.success && profileResponse.data != null) {
          await _storageService.saveUserData(profileResponse.data!.toJson());
        } else {
          await _storageService.saveUserData(response.data!.user.toJson());
        }
      } catch (e) {
        await _storageService.saveUserData(response.data!.user.toJson());
      }
      
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
      
      // Fetch complete profile data to get profile image URL
      try {
        final profileResponse = await getProfile();
        if (profileResponse.success && profileResponse.data != null) {
          await _storageService.saveUserData(profileResponse.data!.toJson());
        } else {
          await _storageService.saveUserData(response.data!.user.toJson());
        }
      } catch (e) {
        await _storageService.saveUserData(response.data!.user.toJson());
      }
      
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
    
    // Clear bookings cache
    BookingsCacheService().clearCache();

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

  // Verify reset OTP (for password reset flow)
  Future<ApiResponse<Map<String, dynamic>>> verifyResetOtp({
    required String email,
    required String otp,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.verifyResetOtp,
      body: {
        'email': email,
        'otp': otp,
      },
      fromJson: (json) => json,
    );
  }

  // Reset password with OTP (alternative to resetPassword)
  Future<ApiResponse<Map<String, dynamic>>> resetPasswordWithOtp({
    required String email,
    required String otp,
    required String password,
    required String passwordConfirmation,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.resetPassword,
      body: {
        'email': email,
        'otp': otp,
        'password': password,
        'password_confirmation': passwordConfirmation,
      },
      fromJson: (json) => json,
    );
  }

  // Verify OTP (for email verification after registration)
  Future<ApiResponse<Map<String, dynamic>>> verifyOtp({
    required String otp,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.verifyOtp,
      body: {
        'otp': otp,
      },
      requiresAuth: true,
      fromJson: (json) => json,
    );
  }
  
  // Resend OTP (for email verification)
  Future<ApiResponse<Map<String, dynamic>>> resendOtp() async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.resendOtp,
      requiresAuth: true,
      fromJson: (json) => json,
    );
  }

  // Verify email
  Future<ApiResponse<Map<String, dynamic>>> verifyEmail({
    required String code,
  }) async {
    return await _apiService.post<Map<String, dynamic>>(
      ApiConstants.verifyEmail,
      body: {
        'code': code, // API expects 'code' field
      },
      requiresAuth: true,
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

  // Upload profile image
  Future<ApiResponse<Map<String, dynamic>>> uploadProfileImage(File imageFile) async {
    try {
      
      // Create FormData for multipart upload
      final dio = Dio();
      final token = await _storageService.getToken();
      
      final formData = FormData.fromMap({
        'profile_image': await MultipartFile.fromFile(
          imageFile.path,
          filename: 'profile_image.jpg',
        ),
      });
      
      
      final response = await dio.post(
        '${ApiConstants.apiBaseUrl}${ApiConstants.uploadProfileImage}',
        data: formData,
        options: Options(
          headers: {
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      
      
      if (response.statusCode == 200) {
        final rawData = response.data;
        final responseData = rawData is Map ? Map<String, dynamic>.from(rawData) : <String, dynamic>{};

        // Update local user data with new profile image URL
        final innerData = responseData['data'];
        final profileImageUrl = innerData is Map ? innerData['profile_image_url']?.toString() : null;
        if (profileImageUrl != null) {
          final currentUser = await getCurrentUser();
          if (currentUser != null) {
            final updatedUser = UserModel(
              id: currentUser.id,
              fullName: currentUser.fullName,
              email: currentUser.email,
              userType: currentUser.userType,
              phoneNumber: currentUser.phoneNumber,
              location: currentUser.location,
              agencyName: currentUser.agencyName,
              agentType: currentUser.agentType,
              whatsappNumber: currentUser.whatsappNumber,
              emailVerified: currentUser.emailVerified,
              profilePicture: profileImageUrl,
              emailVerifiedAt: currentUser.emailVerifiedAt,
              phoneVerifiedAt: currentUser.phoneVerifiedAt,
              kycStatus: currentUser.kycStatus,
              kycData: currentUser.kycData,
              createdAt: currentUser.createdAt,
              updatedAt: currentUser.updatedAt,
            );
            
            // Save updated user data
            await _storageService.saveUserData(updatedUser.toJson());
          }
        }
        
        return ApiResponse<Map<String, dynamic>>(
          success: true,
          statusCode: response.statusCode,
          message: responseData['message'] ?? 'Profile image uploaded successfully',
          data: responseData,
        );
      } else {
        return ApiResponse<Map<String, dynamic>>(
          success: false,
          statusCode: response.statusCode,
          message: 'Failed to upload profile image',
          data: response.data,
        );
      }
    } catch (e) {
      return ApiResponse<Map<String, dynamic>>(
        success: false,
        statusCode: 500,
        message: 'Error uploading profile image: $e',
        data: null,
      );
    }
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

  // Get KYC status - uses appropriate endpoint based on user type
  Future<ApiResponse<KycStatusResponse>> getKycStatus() async {
    // Get current user to determine their type
    final userType = await getUserType();

    print('🟢🟢🟢 [AuthService] getKycStatus called');
    print('🟢 [AuthService] User type: $userType');

    if (userType != null && userType != 'home_seeker') {
      print('🟢 [AuthService] Fetching AGENT KYC status from: ${ApiConstants.kycAgentStatus}');
      final response = await _apiService.get<KycStatusResponse>(
        ApiConstants.kycAgentStatus,
        requiresAuth: true,
        fromJson: (json) => KycStatusResponse.fromJson(json),
      );

      print('🟢 [AuthService] Agent KYC Response:');
      print('🟢   - Success: ${response.success}');
      print('🟢   - Status Code: ${response.statusCode}');
      print('🟢   - Message: ${response.message}');
      print('🟢   - Data: ${response.data}');

      // If agent endpoint returns 404, try user endpoint as fallback
      if (response.statusCode == 404) {
        print('🟢 [AuthService] Agent endpoint returned 404, trying user endpoint as fallback');
        return await _getUserKycStatus();
      }
      return response;
    } else {
      print('🟢 [AuthService] User is not agent, fetching USER KYC status');
      return await _getUserKycStatus();
    }
  }

  // Get user KYC status with fallback handling
  Future<ApiResponse<KycStatusResponse>> _getUserKycStatus() async {
    final response = await _apiService.get<KycStatusResponse>(
      ApiConstants.kycUserStatus,
      requiresAuth: true,
      fromJson: (json) => KycStatusResponse.fromJson(json),
    );
    
    // If user endpoint also returns 404, treat as KYC incomplete (show dialog)
    if (response.statusCode == 404) {
      return ApiResponse.success(
        data: null, // null data means KYC incomplete
        message: 'KYC not started - endpoint not available yet',
        statusCode: 200,
      );
    }
    return response;
  }

  // Clear all user data (local logout)
  Future<void> clearUserData() async {
    await _storageService.clearAll();
  }

  // Request phone verification code
  Future<ApiResponse<void>> requestPhoneVerification() async {
    
    return await _apiService.post<void>(
      ApiConstants.phoneVerifyRequest,
      requiresAuth: true,
      fromJson: (json) => null, // No response body expected
    );
  }

  // Verify phone with code
  Future<ApiResponse<void>> verifyPhone(String code) async {
    
    final requestData = {
      'code': code,
    };
    
    return await _apiService.post<void>(
      ApiConstants.phoneVerify,
      body: requestData,
      requiresAuth: true,
      fromJson: (json) => null, // No response body expected
    );
  }

  // Request email verification code (for the new verification flow)
  Future<ApiResponse<void>> requestNewEmailVerification() async {
    
    return await _apiService.post<void>(
      ApiConstants.emailVerifyRequest,
      requiresAuth: true,
      fromJson: (json) => null, // No response body expected
    );
  }

  // Verify email with code (for the new verification flow)
  Future<ApiResponse<void>> verifyNewEmail(String code) async {
    
    final requestData = {
      'code': code,
    };
    
    return await _apiService.post<void>(
      ApiConstants.emailVerify,
      body: requestData,
      requiresAuth: true,
      fromJson: (json) => null, // No response body expected
    );
  }

  // Submit agent KYC
  Future<ApiResponse<void>> submitAgentKyc(AgentKycRequest request) async {
    print('🔵🔵🔵 [AUTH SERVICE] ========================================');
    print('🔵 [AUTH SERVICE] SUBMITTING AGENT KYC');
    print('🔵 [AUTH SERVICE] Endpoint: ${ApiConstants.kycAgentSubmit}');
    print('🔵 [AUTH SERVICE] ========================================');
    
    try {
      final fields = request.toFormFields();
      final files = request.toFormFiles();
      
      print('🔵 [AUTH SERVICE] About to send request...');
      print('🔵 [AUTH SERVICE] Fields count: ${fields.length}');
      print('🔵 [AUTH SERVICE] Files count: ${files.length}');
      
      final response = await _apiService.postFormData<void>(
        ApiConstants.kycAgentSubmit,
        fields: fields,
        files: files,
        requiresAuth: true,
        fromJson: (json) => null, // No response body expected
      );
      
      print('🔵 [AUTH SERVICE] Response received:');
      print('  - Success: ${response.success}');
      print('  - Message: ${response.message}');
      print('  - Status Code: ${response.statusCode}');
      if (response.errors != null) {
        print('  - Errors: ${response.errors}');
      }
      print('🔵🔵🔵 [AUTH SERVICE] ========================================');
      
      return response;
    } catch (e, stackTrace) {
      print('🔴 [AUTH SERVICE] ERROR submitting agent KYC: $e');
      print('🔴 [AUTH SERVICE] Stack trace: $stackTrace');
      return ApiResponse.error(
        message: 'Failed to submit KYC: $e',
        statusCode: 0,
      );
    }
  }

  // Submit user KYC
  Future<ApiResponse<void>> submitUserKyc(UserKycRequest request) async {
    print('🟢🟢🟢 [AUTH SERVICE] ========================================');
    print('🟢 [AUTH SERVICE] SUBMITTING USER/HOMESEEKER KYC');
    print('🟢 [AUTH SERVICE] Endpoint: ${ApiConstants.kycUserSubmit}');
    print('🟢 [AUTH SERVICE] ========================================');
    
    try {
      final fields = request.toFormFields();
      final files = request.toFormFiles();
      
      print('🟢 [AUTH SERVICE] About to send request...');
      print('🟢 [AUTH SERVICE] Fields count: ${fields.length}');
      print('🟢 [AUTH SERVICE] Files count: ${files.length}');
      
      final response = await _apiService.postFormData<void>(
        ApiConstants.kycUserSubmit,
        fields: fields,
        files: files,
        requiresAuth: true,
        fromJson: (json) => null, // No response body expected
      );
      
      print('🟢 [AUTH SERVICE] Response received:');
      print('  - Success: ${response.success}');
      print('  - Message: ${response.message}');
      print('  - Status Code: ${response.statusCode}');
      if (response.errors != null) {
        print('  - Errors: ${response.errors}');
      }
      print('🟢🟢🟢 [AUTH SERVICE] ========================================');
      
      return response;
    } catch (e, stackTrace) {
      print('🔴 [AUTH SERVICE] ERROR submitting user KYC: $e');
      print('🔴 [AUTH SERVICE] Stack trace: $stackTrace');
      return ApiResponse.error(
        message: 'Failed to submit KYC: $e',
        statusCode: 0,
      );
    }
  }
} 