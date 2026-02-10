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

  /// Create from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    // Parse features from JSON
    List<String>? features;
    if (json['features'] != null) {
      final featuresList = json['features'] as List<dynamic>;
      features = featuresList.map((feature) => feature.toString()).toList();
    }
    
    // Parse images array
    String? imageUrl;
    List<Map<String, dynamic>>? images;
    bool hasFeaturedImage = false;
    
    if (json['images'] != null && json['images'] is List && (json['images'] as List).isNotEmpty) {
      final imagesList = json['images'] as List<dynamic>;
      
      // Store all images
      images = imagesList.map((image) {
        final imageMap = image as Map<String, dynamic>;
        // Ensure full URLs are properly formatted
        if (imageMap['full_url'] != null) {
          final rawUrl = imageMap['full_url'] as String;
          if (rawUrl.startsWith('property-images/') || rawUrl.startsWith('uploads/')) {
            imageMap['full_url'] = 'https://proapi.proplinq.com/storage/$rawUrl';
          }
        }
        // Check if this image is featured
        if (imageMap['is_featured'] == true) {
          hasFeaturedImage = true;
        }
        return imageMap;
      }).toList();
      
      // Set the first image as the primary imageUrl for backward compatibility
      final firstImage = images.first;
      String? rawImageUrl = firstImage['full_url'] as String? ?? firstImage['image_url'] as String?;
      if (rawImageUrl != null) {
        // If it's a relative path, construct the full URL
        if (rawImageUrl.startsWith('property-images/') || rawImageUrl.startsWith('uploads/')) {
          imageUrl = 'https://proapi.proplinq.com/storage/$rawImageUrl';
        } else {
          imageUrl = rawImageUrl;
        }
      }
    } else if (json['images_full_urls'] != null && json['images_full_urls'] is List && (json['images_full_urls'] as List).isNotEmpty) {
      // Handle alternative structure with images_full_urls array
      final imagesList = json['images_full_urls'] as List<dynamic>;
      images = imagesList.map((url) {
        return {
          'full_url': url.toString(),
          'is_featured': false,
        };
      }).toList();
      
      // Set the first image as the primary imageUrl
      if (images.isNotEmpty) {
        imageUrl = images.first['full_url'] as String;
      }
    }
    
    // Determine if property is featured
    // Check property-level is_featured first, then check if any image has is_featured: true
    bool isFeatured = json['is_featured'] as bool? ?? false;
    if (!isFeatured && hasFeaturedImage) {
      isFeatured = true;
    }
    
    // Parse property360_images array
    List<Map<String, dynamic>>? property360Images;
    if (json['property360_images'] != null && json['property360_images'] is List && (json['property360_images'] as List).isNotEmpty) {
      final property360ImagesList = json['property360_images'] as List<dynamic>;
      
      // Store all 360 images
      property360Images = property360ImagesList.map((image) {
        final imageMap = image as Map<String, dynamic>;
        // Ensure full URLs are properly formatted
        if (imageMap['full_url'] != null) {
          final rawUrl = imageMap['full_url'] as String;
          if (rawUrl.startsWith('property-360-images/') || rawUrl.startsWith('uploads/')) {
            imageMap['full_url'] = 'https://proapi.proplinq.com/storage/$rawUrl';
          }
        }
        return imageMap;
      }).toList();
      
    } else if (json['property_360_images_full_urls'] != null && json['property_360_images_full_urls'] is List && (json['property_360_images_full_urls'] as List).isNotEmpty) {
      // Handle alternative field structure
      final property360ImagesList = json['property_360_images_full_urls'] as List<dynamic>;
      
      // Store all 360 images with proper structure
      property360Images = property360ImagesList.map((image) {
        final imageMap = image as Map<String, dynamic>;
        // Convert the alternative structure to match our expected format
        return {
          'id': imageMap['id'],
          'property_id': imageMap['id'], // Use id as property_id if not present
          'full_url': imageMap['url'], // Map 'url' to 'full_url'
          'is_featured': false,
          'created_at': DateTime.now().toIso8601String(),
          'updated_at': DateTime.now().toIso8601String(),
        };
      }).toList();
      
    } else {
      // Check if 360 images are stored in the regular images array
      if (images != null && images.isNotEmpty) {
        final image360List = <Map<String, dynamic>>[];
        for (final image in images) {
          final imageMap = image;
          final fullUrl = imageMap['full_url'] as String?;
          
          // Check if this is a 360 image based on the URL path
          if (fullUrl != null && fullUrl.contains('property-360-images/')) {
            image360List.add(imageMap);
          }
        }
        
        if (image360List.isNotEmpty) {
          property360Images = image360List;
        } else {
        }
      } else {
      }
    }
    
    // Parse video URL
    String? videoUrl;
    if (json['video_url'] != null && json['video_url'].toString().isNotEmpty) {
      videoUrl = json['video_url'] as String;
    } else {
    }
    
    // Parse user data
    PropertyUser? user;
    if (json['user'] != null) {
      user = PropertyUser.fromJson(json['user'] as Map<String, dynamic>);
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
      images: images,
      property360Images: property360Images,
      videoUrl: videoUrl,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
      features: features,
      isFavorite: json['is_liked'] as bool? ?? json['isLiked'] as bool? ?? false,
      isFeatured: isFeatured,
      user: user,
      rawJson: json, // Store raw JSON to preserve ratings and other fields
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

  /// Create from JSON
  factory PropertyUser.fromJson(Map<String, dynamic> json) {
    // Handle new structure with full_name or construct from first_name/last_name
    String fullName;
    if (json['full_name'] != null && json['full_name'].toString().isNotEmpty) {
      fullName = json['full_name'] as String;
    } else if (json['first_name'] != null || json['last_name'] != null) {
      final firstName = json['first_name']?.toString() ?? '';
      final lastName = json['last_name']?.toString() ?? '';
      fullName = '$firstName $lastName'.trim();
      if (fullName.isEmpty) {
        fullName = json['name']?.toString() ?? 'Unknown';
      }
    } else {
      fullName = json['name']?.toString() ?? 'Unknown';
    }
    
    // Handle profile_image vs profile_image_full_url
    String? profileImageFullUrl = json['profile_image_full_url'] as String?;
    if (profileImageFullUrl == null && json['profile_image'] != null) {
      profileImageFullUrl = json['profile_image'] as String;
      // Construct full URL if it's a relative path
      if (profileImageFullUrl.startsWith('profile_images/') || profileImageFullUrl.startsWith('uploads/')) {
        profileImageFullUrl = 'https://proapi.proplinq.com/storage/$profileImageFullUrl';
      }
    }
    
    // Handle kyc_status - create PropertyKyc if kyc_status exists
    PropertyKyc? kyc;
    if (json['kyc'] != null) {
      kyc = PropertyKyc.fromJson(json['kyc'] as Map<String, dynamic>);
    } else if (json['kyc_status'] != null) {
      // Create a minimal KYC object from kyc_status
      kyc = PropertyKyc(
        userId: json['id'] as int,
        status: json['kyc_status'] as String,
      );
    }
    
    return PropertyUser(
      id: json['id'] as int,
      fullName: fullName,
      email: json['email'] as String,
      phoneNumber: json['phone_number'] as String?,
      location: json['location'] as String?,
      agencyName: json['agency_name'] as String?,
      agentType: json['agent_type'] as String?,
      whatsappNumber: json['whatsapp_number'] as String?,
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