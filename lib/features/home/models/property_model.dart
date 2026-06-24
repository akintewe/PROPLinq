String _toTitleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

/// Property model representing a real estate property
class PropertyModel {
  final int id;
  final String? uuid;
  final int userId;
  final String type;
  final String title;
  final String description;
  final String price;
  final String category;
  final String location;
  final String? imageUrl;
  final List<Map<String, dynamic>>? images;
  final List<Map<String, dynamic>>? property360Images;
  final String? videoUrl;
  final int? bedrooms;
  final int? bathrooms;
  final double? area;
  final List<String>? features;
  final bool isFavorite;
  final bool isFeatured;
  final PropertyUser? user;
  final Map<String, dynamic>? rawJson; // Store raw JSON to preserve ratings and other fields

  const PropertyModel({
    required this.id,
    this.uuid,
    required this.userId,
    required this.type,
    required this.title,
    required this.description,
    required this.price,
    required this.category,
    required this.location,
    this.imageUrl,
    this.images,
    this.property360Images,
    this.videoUrl,
    this.bedrooms,
    this.bathrooms,
    this.area,
    this.features,
    this.isFavorite = false,
    this.isFeatured = false,
    this.user,
    this.rawJson,
  });

  /// Create a copy of this model with updated fields
  PropertyModel copyWith({
    int? id,
    String? uuid,
    int? userId,
    String? type,
    String? title,
    String? description,
    String? price,
    String? category,
    String? location,
    String? imageUrl,
    List<Map<String, dynamic>>? images,
    List<Map<String, dynamic>>? property360Images,
    String? videoUrl,
    int? bedrooms,
    int? bathrooms,
    double? area,
    List<String>? features,
    bool? isFavorite,
    bool? isFeatured,
    PropertyUser? user,
    Map<String, dynamic>? rawJson,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      uuid: uuid ?? this.uuid,
      userId: userId ?? this.userId,
      type: type ?? this.type,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      category: category ?? this.category,
      location: location ?? this.location,
      imageUrl: imageUrl ?? this.imageUrl,
      images: images ?? this.images,
      property360Images: property360Images ?? this.property360Images,
      videoUrl: videoUrl ?? this.videoUrl,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      features: features ?? this.features,
      isFavorite: isFavorite ?? this.isFavorite,
      isFeatured: isFeatured ?? this.isFeatured,
      user: user ?? this.user,
      rawJson: rawJson ?? this.rawJson,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'uuid': uuid,
      'user_id': userId,
      'type': type,
      'title': title,
      'description': description,
      'price': price,
      'category': category,
      'location': location,
      'image_url': imageUrl,
      'images': images,
      'property360_images': property360Images,
      'video_url': videoUrl,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'features': features,
      'isLiked': isFavorite,
      'user': user?.toJson(),
    };
  }

  /// Create from JSON — tolerant of missing/wrong-type fields
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Parse features
    List<String>? features;
    final rawFeatures = json['features'];
    if (rawFeatures is List) {
      features = rawFeatures.map((f) => f?.toString() ?? '').where((s) => s.isNotEmpty).toList();
    } else if (rawFeatures is String && rawFeatures.isNotEmpty) {
      features = rawFeatures.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
    }

    // Helper: normalise a relative image path to a full URL
    String normaliseUrl(String raw) {
      if (raw.startsWith('property-images/') ||
          raw.startsWith('property-360-images/') ||
          raw.startsWith('uploads/')) {
        return 'https://proapi.proplinq.com/storage/$raw';
      }
      return raw;
    }

    // Parse images array
    String? imageUrl;
    List<Map<String, dynamic>>? images;
    bool hasFeaturedImage = false;

    final rawImages = json['images'];
    if (rawImages is List && rawImages.isNotEmpty) {
      images = rawImages
          .whereType<Map>()
          .map((img) {
            final m = Map<String, dynamic>.from(img);
            // API changed field from full_url → url; normalise to full_url for all downstream consumers
            final rawUrl = (m['full_url']?.toString().isNotEmpty == true
                    ? m['full_url']
                    : m['url'])
                ?.toString();
            if (rawUrl != null && rawUrl.isNotEmpty) {
              m['full_url'] = normaliseUrl(rawUrl);
            }
            if (m['is_featured'] == true) hasFeaturedImage = true;
            return m;
          })
          .toList();

      if (images.isNotEmpty) {
        final first = images.first;
        final rawUrl = first['full_url']?.toString() ?? first['image_url']?.toString();
        if (rawUrl != null && rawUrl.isNotEmpty) {
          imageUrl = normaliseUrl(rawUrl);
        }
      }
    } else {
      final rawAlt = json['images_full_urls'];
      if (rawAlt is List && rawAlt.isNotEmpty) {
        images = rawAlt.map((url) => <String, dynamic>{
          'full_url': url?.toString() ?? '',
          'is_featured': false,
        }).toList();
        imageUrl = images.first['full_url']?.toString();
      }
    }

    // Determine if property is featured
    final rawFeatured = json['is_featured'];
    bool isFeatured = rawFeatured == true || rawFeatured == 1;
    if (!isFeatured && hasFeaturedImage) isFeatured = true;

    // Parse 360 images
    List<Map<String, dynamic>>? property360Images;
    final raw360 = json['property360_images'];
    final raw360Alt = json['property_360_images_full_urls'];
    if (raw360 is List && raw360.isNotEmpty) {
      property360Images = raw360
          .whereType<Map>()
          .map((img) {
            final m = Map<String, dynamic>.from(img);
            final rawUrl = m['full_url']?.toString();
            if (rawUrl != null && rawUrl.isNotEmpty) {
              m['full_url'] = normaliseUrl(rawUrl);
            }
            return m;
          })
          .toList();
    } else if (raw360Alt is List && raw360Alt.isNotEmpty) {
      property360Images = raw360Alt
          .whereType<Map>()
          .map((img) {
            final m = Map<String, dynamic>.from(img);
            return <String, dynamic>{
              'id': m['id'],
              'property_id': m['id'],
              'full_url': m['url']?.toString() ?? '',
              'is_featured': false,
              'created_at': DateTime.now().toIso8601String(),
              'updated_at': DateTime.now().toIso8601String(),
            };
          })
          .toList();
    } else if (images != null) {
      final list360 = images.where((img) {
        final u = img['full_url']?.toString() ?? '';
        return u.contains('property-360-images/');
      }).toList();
      if (list360.isNotEmpty) property360Images = list360;
    }

    // Parse video URL
    final rawVideo = json['video_url']?.toString();
    final videoUrl = (rawVideo != null && rawVideo.isNotEmpty) ? rawVideo : null;

    // Parse user data
    PropertyUser? user;
    final rawUser = json['user'];
    if (rawUser is Map) {
      try {
        user = PropertyUser.fromJson(Map<String, dynamic>.from(rawUser));
      } catch (_) {}
    }

    // Parse isFavorite — backend may send bool or int (0/1)
    final rawLiked = json['is_liked'] ?? json['isLiked'];
    final isFavorite = rawLiked == true || rawLiked == 1;

    return PropertyModel(
      id: _parseInt(json['id']) ?? 0,
      uuid: json['uuid']?.toString(),
      userId: _parseInt(json['user_id']) ?? 0,
      type: _toTitleCase(json['type']?.toString() ?? ''),
      title: _toTitleCase(json['title']?.toString() ?? ''),
      description: json['description']?.toString() ?? '',
      price: json['price']?.toString() ?? '0',
      category: _toTitleCase(json['category']?.toString() ?? ''),
      location: json['location']?.toString() ?? '',
      imageUrl: imageUrl,
      images: images,
      property360Images: property360Images,
      videoUrl: videoUrl,
      bedrooms: _parseInt(json['bedrooms']),
      bathrooms: _parseInt(json['bathrooms']),
      area: _parseDouble(json['area']),
      features: features,
      isFavorite: isFavorite,
      isFeatured: isFeatured,
      user: user,
      rawJson: json,
    );
  }

  static int? _parseInt(dynamic v) {
    if (v == null) return null;
    if (v is int) return v;
    if (v is double) return v.toInt();
    return int.tryParse(v.toString());
  }

  static double? _parseDouble(dynamic v) {
    if (v == null) return null;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString());
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
  final String? profileImageFullUrl;
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
    this.profileImageFullUrl,
    this.kyc,
  });

  /// Create from JSON — tolerant of missing/wrong-type fields
  factory PropertyUser.fromJson(Map<String, dynamic> json) {
    // Resolve full name from whichever fields exist
    String fullName;
    final rawFullName = json['full_name']?.toString() ?? '';
    if (rawFullName.isNotEmpty) {
      fullName = rawFullName;
    } else {
      final first = json['first_name']?.toString() ?? '';
      final last = json['last_name']?.toString() ?? '';
      fullName = '$first $last'.trim();
      if (fullName.isEmpty) fullName = json['name']?.toString() ?? 'Unknown';
    }

    // Resolve profile image URL
    String? profileImageFullUrl = json['profile_image_full_url']?.toString();
    if (profileImageFullUrl == null || profileImageFullUrl.isEmpty) {
      profileImageFullUrl = json['profile_image']?.toString();
    }
    if (profileImageFullUrl != null &&
        (profileImageFullUrl.startsWith('profile_images/') ||
            profileImageFullUrl.startsWith('uploads/'))) {
      profileImageFullUrl = 'https://proapi.proplinq.com/storage/$profileImageFullUrl';
    }

    // Resolve KYC
    PropertyKyc? kyc;
    final rawKyc = json['kyc'];
    if (rawKyc is Map) {
      try {
        kyc = PropertyKyc.fromJson(Map<String, dynamic>.from(rawKyc));
      } catch (_) {}
    } else {
      final kycStatus = json['kyc_status']?.toString();
      if (kycStatus != null && kycStatus.isNotEmpty) {
        kyc = PropertyKyc(
          userId: PropertyModel._parseInt(json['id']) ?? 0,
          status: kycStatus,
        );
      }
    }

    return PropertyUser(
      id: PropertyModel._parseInt(json['id']) ?? 0,
      fullName: fullName,
      email: json['email']?.toString() ?? '',
      phoneNumber: json['phone_number']?.toString(),
      location: json['location']?.toString(),
      agencyName: json['agency_name']?.toString(),
      agentType: json['agent_type']?.toString(),
      whatsappNumber: json['whatsapp_number']?.toString(),
      profileImageFullUrl: profileImageFullUrl,
      kyc: kyc,
    );
  }

  /// Get verification status text
  String get verificationStatus {
    if (kyc == null) return 'Unverified';
    switch (kyc!.status.toLowerCase()) {
      case 'verified':
      case 'approved':
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
    final status = kyc?.status.toLowerCase();
    return status == 'verified' || status == 'approved';
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
      'profile_image_full_url': profileImageFullUrl,
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

  /// Create from JSON — tolerant of missing/wrong-type fields
  factory PropertyKyc.fromJson(Map<String, dynamic> json) {
    return PropertyKyc(
      userId: PropertyModel._parseInt(json['user_id']) ?? 0,
      status: json['status']?.toString() ?? 'unknown',
      utilityBillFullUrl: json['utility_bill_full_url']?.toString(),
      bankStatementFullUrl: json['bank_statement_full_url']?.toString(),
      cacDocumentFullUrl: json['cac_document_full_url']?.toString(),
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