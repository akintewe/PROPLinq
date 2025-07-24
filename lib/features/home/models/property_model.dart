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
    
    return PropertyModel(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      type: json['type'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: json['price'] as String,
      category: json['category'] as String,
      location: json['location'] as String,
      imageUrl: json['image_url'] as String?,
      bedrooms: json['bedrooms'] as int?,
      bathrooms: json['bathrooms'] as int?,
      area: json['area'] != null ? (json['area'] as num).toDouble() : null,
      features: features,
      isFavorite: json['is_favorite'] as bool? ?? false,
    );
  }

  /// Formatted price string
  String get formattedPrice {
    final priceValue = double.tryParse(price) ?? 0.0;
    if (priceValue >= 1000000) {
      return '\$${(priceValue / 1000000).toStringAsFixed(1)}M';
    } else if (priceValue >= 1000) {
      return '\$${(priceValue / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${priceValue.toStringAsFixed(0)}';
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