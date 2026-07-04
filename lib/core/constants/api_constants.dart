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
  static String rateProperty(String uuid) => '/properties/$uuid/rate';
  static String promoteProperty(String uuid) => '/properties/$uuid/promote';
  static String markPropertyStatus(String uuid) => '/agent/properties/$uuid/mark-status';
  
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
  static const String agentBookings = '/agent/bookings';
  static String cancelBooking(String uuid) => '/bookings/$uuid/cancel';

  // Room Availability (Public)
  static String roomAvailability(String uuid) => '/rooms/$uuid/availability';

  // Agent Calendar Management
  static String agentCalendarRoom(String uuid) => '/agent/calendar/room/$uuid';
  static String agentBlockRoom(String uuid) => '/agent/calendar/room/$uuid/block';
  static String agentUnblockDates(String uuid) => '/agent/calendar/unblock/$uuid';
  
  // Agent Check-in Endpoints
  static const String agentCheckIn = '/agent/check-in';
  static const String agentCheckInAvailable = '/agent/check-in/available';

  // Social Auth Endpoints (mobile token flow)
  static String socialAuth(String provider) => '/auth/$provider/token';

  // AI Chat Endpoints
  static const String aiChat = '/chat/ai';
  static const String aiChatPublic = '/chat/ai/public';

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
  static const String supportTickets = '/tickets';
  static const String supportChats = '/support/chats';
  static String supportTicket(int id) => '/support/tickets/$id';
  static String supportTicketRespond(int id) => '/support/tickets/$id/respond';
  static String supportTicketClose(int id) => '/support/tickets/$id/close';
  static String supportChatDetails(int id) => '/support/chats/$id';
  static String supportChatRespond(int id) => '/support/chats/$id/respond';
  static String supportChatClose(int id) => '/support/chats/$id/close';
  
  // AppsFlyer OneLink base — handles both installed and non-installed (deferred) cases
  static const String _oneLinkBase = 'https://proplinq.onelink.me/fOvE/ob0squjw';

  // Fallback web URL used as the desktop redirect inside the OneLink
  static const String shareLinkBaseUrl = 'https://www.proplinq.com/property';

  /// Generate a shareable OneLink URL for a property.
  ///
  /// Follows AppsFlyer's standard convention (matching the backend's spec):
  ///   deep_link_value = property_page   (screen type — fixed on the template)
  ///   deep_link_sub1  = {property UUID} (the item id)
  ///   deep_link_sub2  = {property type} (shortlet / hotel / apartment)
  ///
  /// NOTE: af_web_dp deliberately omitted — when present, the AppsFlyer iOS SDK
  /// re-opens that web URL in Safari after the app is already launched via
  /// Universal Link, causing an app→Safari→App Store bounce.
  static String generateShareLink({
    required String propertyId,
    String? propertyType,
  }) {
    final type = _normalisePropertyType(propertyType);
    return '$_oneLinkBase?pid=proplinq_app'
        '&deep_link_value=property_page'
        '&deep_link_sub1=${Uri.encodeComponent(propertyId)}'
        '&deep_link_sub2=${Uri.encodeComponent(type)}';
  }

  /// Normalise property type to the canonical slug used in deep links.
  static String _normalisePropertyType(String? type) {
    switch (type?.toLowerCase()) {
      case 'hotel':
        return 'hotel';
      case 'shortlet':
        return 'shortlet';
      default:
        return 'apartment';
    }
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