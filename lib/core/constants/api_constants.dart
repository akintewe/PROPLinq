class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://proapi.proplinq.com';
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Full base URL with version
  static String get apiBaseUrl => baseUrl + apiVersion;
  
  // Auth Endpoints
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  static const String resendVerification = '/resend-verification';
  
  // User Endpoints
  static const String profile = '/user';
  static const String updateProfile = '/profile/update';
  static const String changePassword = '/change-password';
  static const String uploadProfileImage = '/user/profile-image';
  
  // Property Endpoints
  static const String properties = '/properties';
  static const String createProperty = '/properties';
  static const String updateProperty = '/properties';
  static const String deleteProperty = '/properties';
  static const String searchProperties = '/properties/search';
  static const String favoriteProperties = '/properties/favorites';
  static const String listProperties = '/properties';
  static const String myProperties = '/agent/properties';
  
  // KYC Endpoints
  static const String kycSubmission = '/kyc/submit';
  static const String kycAgentStatus = '/kyc/agent/status';   // For agents
  static const String kycUserStatus = '/kyc/user/status';     // For home seekers
  static const String kycAgentSubmit = '/kyc/agent';          // For agent KYC submission
  static const String kycUserSubmit = '/kyc/user';            // For user KYC submission
  
  // Verification Endpoints
  static const String phoneVerifyRequest = '/phone/verify/request';
  static const String phoneVerify = '/phone/verify';
  static const String emailVerifyRequest = '/email/verify/request';
  static const String emailVerify = '/email/verify';
  
  // Favorites
  static const String getFavourites = '/favourite/get-favourites';
  static const String addFavourite = '/favourite/add-favourite';
  static const String deleteFavourite = '/favourite/delete-favourite';
  
  // Chat Endpoints
  static const String chatWebhook = '/chat/webhook';
  static const String getUserChats = '/get-user-chats';
  
  // Headers
  static Map<String, String> get defaultHeaders => {
    'Accept': 'application/json',
    'Content-Type': 'application/json',
  };
  
  static Map<String, String> getAuthHeaders(String token) => {
    ...defaultHeaders,
    'Authorization': 'Bearer $token',
  };
} 