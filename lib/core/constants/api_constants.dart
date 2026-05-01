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
  static const String deleteAccount = '/user';
  
  // Property Endpoints
  static const String properties = '/properties';
  static const String createProperty = '/properties';
  static const String updateProperty = '/properties';
  static const String deleteProperty = '/properties';
  static const String searchProperties = '/properties/search';
  static const String favoriteProperties = '/properties/favorites';
  static const String listProperties = '/properties';
  static const String listPropertiesPublic = '/properties'; // no auth — guests
  static const String myProperties = '/agent/properties';
  static const String promotedProperties = '/properties/promoted';
  static const String promotedPropertiesPublic = '/properties/promoted'; // no auth — guests
  static String rateProperty(int propertyId) => '/properties/$propertyId/rate';
  static String promoteProperty(int propertyId) => '/properties/$propertyId/promote';
  static String markPropertyStatus(int propertyId) => '/agent/properties/$propertyId/mark-status';
  
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

  // Room Availability (Public)
  static String roomAvailability(int roomId) => '/rooms/$roomId/availability';

  // Agent Calendar Management
  static String agentCalendarRoom(int roomId) => '/agent/calendar/room/$roomId';
  static String agentBlockRoom(int roomId) => '/agent/calendar/room/$roomId/block';
  static String agentUnblockDates(String uuid) => '/agent/calendar/unblock/$uuid';
  
  // Agent Check-in Endpoints
  static const String agentCheckIn = '/agent/check-in';
  static const String agentCheckInAvailable = '/agent/check-in/available';

  // AI Chat Endpoint
  static const String aiChat = '/chat/ai';

  // Agent Ratings Endpoints
  static const String agentPropertiesRatings = '/agent/properties/ratings';
  
  // Subscription Endpoints — disabled (moved to website, Apple IAP policy)
  // static const String subscriptionPlans = '/agent/subscription-plans';
  // static const String paySubscription = '/agent/wallet/pay-subscription';

  // Payment Endpoints
  static const String initializePayment = '/payments/initialize';
  static const String verifyPayment = '/payments/verify';
  static const String listTransactions = '/payments/transactions';

  // Wallet Endpoints
  static const String walletFund = '/agent/wallet/fund';
  static const String walletBalance = '/agent/wallet/balance';
  static const String walletTransactions = '/agent/wallet/transactions';
  static const String walletPaymentCallback = '/agent/wallet/payment-callback';

  // Payout Endpoints
  static const String payoutBanks = '/payouts/banks';

  // Support Endpoints
  static const String supportTickets = '/support/tickets';
  static const String supportChats = '/support/chats';
  static String supportTicket(int id) => '/support/tickets/$id';
  static String supportTicketRespond(int id) => '/support/tickets/$id/respond';
  static String supportTicketClose(int id) => '/support/tickets/$id/close';
  static String supportChatDetails(int id) => '/support/chats/$id';
  static String supportChatRespond(int id) => '/support/chats/$id/respond';
  static String supportChatClose(int id) => '/support/chats/$id/close';
  
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
  
  // AI Chat WebSocket (Laravel Reverb / Pusher-compatible)
  // Note: pusher_channels_flutter package only supports apiKey, cluster, useTLS in init()
  static const bool reverbUseTLS = false;
  // The Reverb app key — update when backend provides the actual key
  static const String reverbAppKey = 'proplinq-reverb-key';

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