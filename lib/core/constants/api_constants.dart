class ApiConstants {
  // Base URL
  static const String baseUrl = 'https://api.v2.proplinq.com';
  
  // API Version
  static const String apiVersion = '/api/v1';
  
  // Full base URL with version
  static String get apiBaseUrl => baseUrl + apiVersion;
  
  // Auth Endpoints
  static const String register = '/register';
  static const String login = '/login';
  static const String logout = '/logout';
  static const String forgotPassword = '/forgot-password';
  static const String verifyResetOtp = '/verify-reset-otp';
  static const String resetPassword = '/reset-password';
  static const String verifyEmail = '/verify-email';
  static const String resendVerification = '/resend-verification';
  
  // User Endpoints
  static const String profile = '/user';
  static const String updateProfile = '/profile/update';
  static const String changePassword = '/change-password';
  static const String uploadProfileImage = '/user/profile-image';
  static const String updatePlayerId = '/update-player-id';
  
  // Property Endpoints
  static const String properties = '/properties';
  static const String createProperty = '/properties';
  static const String updateProperty = '/properties';
  static const String deleteProperty = '/properties';
  static const String searchProperties = '/properties/search';
  static const String favoriteProperties = '/properties/favorites';
  static const String listProperties = '/properties';
  static const String myProperties = '/agent/properties';
  static const String promotedProperties = '/properties/promoted';
  static String rateProperty(int propertyId) => '/properties/$propertyId/rate';
  static String promoteProperty(int propertyId) => '/properties/$propertyId/promote';
  
  // KYC Endpoints
  static const String kycSubmission = '/kyc/submit';
  static const String kycAgentStatus = '/kyc/agent/status';   // For agents
  static const String kycUserStatus = '/kyc/user/status';     // For home seekers
  static const String kycAgentDetails = '/kyc/agent';         // Get agent KYC details
  static const String kycAgentSubmit = '/kyc/agent';          // For agent KYC submission
  static const String kycUserSubmit = '/kyc/user';            // For user KYC submission
  
  // Verification Endpoints
  static const String phoneVerifyRequest = '/phone/verify/request';
  static const String phoneVerify = '/phone/verify';
  static const String emailVerifyRequest = '/email/verify/request';
  static const String emailVerify = '/email/verify';
  static const String verifyOtp = '/verify-otp';
  static const String resendOtp = '/resend-otp';
  
  // Favorites
  static const String getFavourites = '/favourite/get-favourites';
  static const String addFavourite = '/favourite/add-favourite';
  static const String deleteFavourite = '/favourite/delete-favourite';
  
  // Chat Endpoints
  static const String chatWebhook = '/chat/webhook';
  static const String getUserChats = '/get-user-chats';
  static const String updateOnlineStatus = '/chat/update-online-status';
  static const String checkOnlineStatus = '/chat/check-online-status';
  static const String myOnlineStatus = '/chat/my-online-status';
  static String markMessageReceived(int messageId) => '/chat/mark-received/$messageId';
  
  // Booking Endpoints
  static const String bookings = '/bookings';
  static String cancelBooking(int bookingId) => '/bookings/$bookingId/cancel';
  
  // Agent Ratings Endpoints
  static const String agentPropertiesRatings = '/agent/properties/ratings';
  
  // Subscription Endpoints
  static const String subscriptionPlans = '/agent/subscription-plans';
  static const String paySubscription = '/agent/wallet/pay-subscription';
  
  // AppsFlyer OneLink Configuration
  // Template ID from AppsFlyer Dashboard: fOvE
  // Custom domain: app.proplinq.com (CNAME → proplinq.customlinks.appsflyer.com)
  static const String appsFlyerOneLinkTemplateId = 'fOvE';
  static const String appsFlyerOneLinkBaseUrl = 'https://app.proplinq.com';
  
  /// Generate AppsFlyer OneLink URL for sharing properties
  /// Format: https://proplinq.onelink.me/fOvE/{propertyId}?pid=referral&c=in_app_share&deep_link_value=property_page&deep_link_sub1={propertyId}
  /// Alternative format (if path-based doesn't work): https://proplinq.onelink.me/fOvE/?pid=referral&c=in_app_share&deep_link_value=property_page&deep_link_sub1={propertyId}
  static String generateShareLink({
    required String propertyId,
    String? propertyType,
  }) {
    // Map property type to deep_link_value
    final deepLinkValue = 'property_page';
    
    // Build the OneLink URL with AppsFlyer parameters
    // Using property ID as path segment for better compatibility
    // Format: https://proplinq.onelink.me/fOvE/{propertyId}?params
    final uri = Uri.parse('$appsFlyerOneLinkBaseUrl/$appsFlyerOneLinkTemplateId/$propertyId').replace(
      queryParameters: {
        'pid': 'referral',
        'c': 'in_app_share',
        'deep_link_value': deepLinkValue,
        'deep_link_sub1': propertyId,
      },
    );
    
    return uri.toString();
  }
  
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