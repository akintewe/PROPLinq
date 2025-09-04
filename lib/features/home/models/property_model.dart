/// Property model representing a real estate property
class PropertyModel {
  final int id;
  final int userId;
  final String type;
  final String title;
  final String description;
  final String price;
  final String category;
  final String location;
  final String? imageUrl;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final List<String>? features;
  final bool isFavorite;
  final PropertyUser? user;

  const PropertyModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.location,
    this.imageUrl,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.features,
    this.isFavorite = false,
    this.user,
  });

  /// Create a copy of this model with updated fields
  PropertyModel copyWith({
    int? id,
    int? userId,
    String? type,
    String? title,
    String? description,
    String? price,
    String? category,
    String? location,
    String? imageUrl,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? features,
    bool? isFavorite,
    PropertyUser? user,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      features: features ?? this.features,
      isFavorite: isFavorite ?? this.isFavorite,
      user: user ?? this.user,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'location': location,
      'image_url': imageUrl,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'features': features,
      'is_favorite': isFavorite,
      'user': user?.toJson(),
    };
  }

  /// Create from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Parse features from JSON
    List<String>? features;
    if (json['features'] != null) {
      final featuresList = json['features'] as List<dynamic>;
      features = featuresList.map((feature) => feature.toString()).toList();
    }
    
    // Parse image URL from images array
    String? imageUrl;
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final images = json['images'] as List<dynamic>;
      print('🖼️ PropertyModel: Found ${images.length} images in API data');
      final firstImage = images.first as Map<String, dynamic>;
      imageUrl = firstImage['full_url'] as String?;
      print('✅ PropertyModel: Extracted imageUrl: $imageUrl');
    } else {
      print('❌ PropertyModel: No images found in API data');
    }
    
    // Parse user data
    PropertyUser? user;
    if (json['user'] != null) {
      user = PropertyUser.fromJson(json['user'] as Map<String, dynamic>);
      print('👤 PropertyModel: Parsed user data - KYC Status: ${user.verificationStatus}');
    }
    
    return PropertyModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      category: json['category'] as String,
      location: json['location'] as String,
      imageUrl: imageUrl,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
      features: features,
      isFavorite: json['is_favorite'] as bool? ?? false,
      user: user,
    );
  }

  /// Formatted price string
  String get formattedPrice {
    final priceValue = double.tryParse(price) ?? 0.0;
    if (priceValue >= 1000000) {
      return '₦${(priceValue / 1000000).toStringAsFixed(1)}M';
    } else if (priceValue >= 1000) {
      return '₦${(priceValue / 1000).toStringAsFixed(0)}K';
    } else {
      return '₦${priceValue.toStringAsFixed(0)}';
    }
  }

  /// Formatted area string
  String get formattedArea {
    if (area == null) return 'N/A';
    return '${area!.toStringAsFixed(0)} sq ft';
  }

  @override
  String toString() {
    return 'PropertyModel(id: $id, title: $title, price: $price)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PropertyModel && other.id == id;
  }

  @override
  int get hashCode {
    return id.hashCode;
  }
}

/// User information associated with a property
class PropertyUser {
  final int id;
  final String fullName;
  final String email;
  final String? phoneNumber;
  final String? location;
  final String? agencyName;
  final String? agentType;
  final String? whatsappNumber;
  final PropertyKyc? kyc;

  const PropertyUser({
    required this.id,
    required this.fullName,
    required this.email,
    this.phoneNumber,
    this.location,
    this.agencyName,
    this.agentType,
    this.whatsappNumber,
    this.kyc,
  });

  /// Create from JSON
  factory PropertyUser.fromJson(Map<String, dynamic> json) {
    return PropertyUser(
      id: json['id'] as int,
      fullName: json['full_name'] as String,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      location: json['location'] as String?,
      agencyName: json['agency_name'] as String?,
      agentType: json['agent_type'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
      kyc: json['kyc'] != null ? PropertyKyc.fromJson(json['kyc'] as Map<String, dynamic>) : null,
    );
  }

  /// Get verification status text
  String get verificationStatus {
    if (kyc == null) return 'Unverified';
    switch (kyc!.status) {
      case 'verified':
        return 'Verified';
      case 'pending':
        return 'Pending';
      case 'rejected':
        return 'Rejected';
      default:
        return 'Unverified';
    }
  }

  /// Check if user is verified
  bool get isVerified {
    return kyc?.status == 'verified';
  }

  /// Check if user is pending verification
  bool get isPending {
    return kyc?.status == 'pending';
  }

  /// Check if user is rejected
  bool get isRejected {
    return kyc?.status == 'rejected';
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'full_name': fullName,
      'email': email,
      'phone_number': phoneNumber,
      'location': location,
      'agency_name': agencyName,
      'agent_type': agentType,
      'whatsapp_number': whatsappNumber,
      'kyc': kyc?.toJson(),
    };
  }
}

/// KYC information for a property user
class PropertyKyc {
  final int userId;
  final String status;
  final String? utilityBillFullUrl;
  final String? bankStatementFullUrl;
  final String? cacDocumentFullUrl;

  const PropertyKyc({
    required this.userId,
    required this.status,
    this.utilityBillFullUrl,
    this.bankStatementFullUrl,
    this.cacDocumentFullUrl,
  });

  /// Create from JSON
  factory PropertyKyc.fromJson(Map<String, dynamic> json) {
    return PropertyKyc(
      userId: json['user_id'] as int,
      status: json['status'] as String,
      utilityBillFullUrl: json['utility_bill_full_url'] as String?,
      bankStatementFullUrl: json['bank_statement_full_url'] as String?,
      cacDocumentFullUrl: json['cac_document_full_url'] as String?,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'status': status,
      'utility_bill_full_url': utilityBillFullUrl,
      'bank_statement_full_url': bankStatementFullUrl,
      'cac_document_full_url': cacDocumentFullUrl,
    };
  }
} 