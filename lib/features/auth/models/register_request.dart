class RegisterRequest {
  final String fullName;
  final String email;
  final String password;
  final String passwordConfirmation;
  final String userType;
  final String phoneNumber;
  final String location;
  final bool termsAccepted;
  final String? agencyName;
  final String? agentType;
  final String? whatsappNumber;
  final String? pendingProductId;

  RegisterRequest({
    required this.fullName,
    required this.email,
    required this.password,
    required this.passwordConfirmation,
    required this.userType,
    required this.phoneNumber,
    required this.location,
    required this.termsAccepted,
    this.agencyName,
    this.agentType,
    this.whatsappNumber,
    this.pendingProductId,
  });

  Map<String, dynamic> toJson() {
    return {
      'full_name': fullName,
      'email': email,
      'password': password,
      'password_confirmation': passwordConfirmation,
      'user_type': userType,
      'phone_number': phoneNumber,
      'location': location,
      'terms_accepted': termsAccepted,
      if (agencyName != null) 'agency_name': agencyName,
      if (agentType != null) 'agent_type': agentType,
      if (whatsappNumber != null) 'whatsapp_number': whatsappNumber,
      if (pendingProductId != null) 'pending_product_id': pendingProductId,
    };
  }
} 