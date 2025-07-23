class KycStatusResponse {
  final String status; // e.g., 'pending', 'verified', 'rejected', 'not_started'
  final bool isRequired;
  final String? message;
  final Map<String, dynamic>? details;

  KycStatusResponse({
    required this.status,
    required this.isRequired,
    this.message,
    this.details,
  });

  factory KycStatusResponse.fromJson(Map<String, dynamic> json) {
    return KycStatusResponse(
      status: json['status'] ?? 'not_started',
      isRequired: json['is_required'] ?? true,
      message: json['message'],
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'status': status,
      'is_required': isRequired,
      'message': message,
      'details': details,
    };
  }

  // Helper method to determine if KYC dialog should be shown
  bool shouldShowKycDialog() {
    // Show dialog only if KYC is required and status is 'not_started' or 'rejected'
    // Don't show dialog for 'pending' or 'verified' statuses
    return isRequired && (status == 'not_started' || status == 'rejected');
  }

  // Helper method to check if KYC is completed and verified
  bool isKycVerified() {
    return status == 'verified';
  }

  // Helper method to check if KYC is pending review
  bool isKycPending() {
    return status == 'pending';
  }

  // Helper method to check if KYC was rejected
  bool isKycRejected() {
    return status == 'rejected';
  }

  // Helper method to check if user hasn't started KYC
  bool isKycNotStarted() {
    return status == 'not_started';
  }

  // Example responses for testing - these show what your API might return
  static KycStatusResponse exampleNotStarted() {
    return KycStatusResponse(
      status: 'not_started',
      isRequired: true,
      message: 'KYC verification is required. Please complete your verification.',
      details: {
        'required_documents': ['id_card', 'bank_statement', 'utility_bill'],
        'estimated_completion_time': '5-10 minutes'
      },
    );
  }

  static KycStatusResponse examplePending() {
    return KycStatusResponse(
      status: 'pending',
      isRequired: true,
      message: 'Your KYC submission is under review. We will notify you once completed.',
      details: {
        'submitted_at': '2024-01-15T10:30:00Z',
        'expected_review_time': '1-3 business days'
      },
    );
  }

  static KycStatusResponse exampleVerified() {
    return KycStatusResponse(
      status: 'verified',
      isRequired: true,
      message: 'Your KYC verification is complete. You can now access all features.',
      details: {
        'verified_at': '2024-01-16T14:22:00Z',
        'verification_level': 'full'
      },
    );
  }

  static KycStatusResponse exampleRejected() {
    return KycStatusResponse(
      status: 'rejected',
      isRequired: true,
      message: 'Your KYC submission was rejected. Please resubmit with valid documents.',
      details: {
        'rejected_at': '2024-01-16T09:15:00Z',
        'rejection_reason': 'Invalid document quality',
        'can_resubmit': true
      },
    );
  }

  static KycStatusResponse exampleNotRequired() {
    return KycStatusResponse(
      status: 'not_required',
      isRequired: false,
      message: 'KYC verification is not required for your account type.',
      details: {
        'account_type': 'basic',
        'restrictions': []
      },
    );
  }

  @override
  String toString() {
    return 'KycStatusResponse(status: $status, isRequired: $isRequired, shouldShowDialog: ${shouldShowKycDialog()}, message: $message)';
  }
} 