/// Property model representing a real estate property
class PropertyModel {
  final String id;
  final String title;
  final String address;
  final double price;
  final String imageUrl;
  final int bedrooms;
  final int bathrooms;
  final double area;
  final String propertyType;
  final bool isFavorite;
  final String agentName;
  final String agentPhone;

  const PropertyModel({
    required this.id,
    required this.title,
    required this.address,
    required this.price,
    required this.imageUrl,
    required this.bedrooms,
    required this.bathrooms,
    required this.area,
    required this.propertyType,
    this.isFavorite = false,
    required this.agentName,
    required this.agentPhone,
  });

  /// Create a copy of this model with updated fields
  PropertyModel copyWith({
    String? id,
    String? title,
    String? address,
    double? price,
    String? imageUrl,
    int? bedrooms,
    int? bathrooms,
    double? area,
    String? propertyType,
    bool? isFavorite,
    String? agentName,
    String? agentPhone,
  }) {
    return PropertyModel(
      id: id ?? this.id,
      title: title ?? this.title,
      address: address ?? this.address,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      bedrooms: bedrooms ?? this.bedrooms,
      bathrooms: bathrooms ?? this.bathrooms,
      area: area ?? this.area,
      propertyType: propertyType ?? this.propertyType,
      isFavorite: isFavorite ?? this.isFavorite,
      agentName: agentName ?? this.agentName,
      agentPhone: agentPhone ?? this.agentPhone,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'address': address,
      'price': price,
      'imageUrl': imageUrl,
      'bedrooms': bedrooms,
      'bathrooms': bathrooms,
      'area': area,
      'propertyType': propertyType,
      'isFavorite': isFavorite,
      'agentName': agentName,
      'agentPhone': agentPhone,
    };
  }

  /// Create from JSON
  factory PropertyModel.fromJson(Map<String, dynamic> json) {
    return PropertyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      address: json['address'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      bedrooms: json['bedrooms'] as int,
      bathrooms: json['bathrooms'] as int,
      area: (json['area'] as num).toDouble(),
      propertyType: json['propertyType'] as String,
      isFavorite: json['isFavorite'] as bool? ?? false,
      agentName: json['agentName'] as String,
      agentPhone: json['agentPhone'] as String,
    );
  }

  /// Formatted price string
  String get formattedPrice {
    if (price >= 1000000) {
      return '\$${(price / 1000000).toStringAsFixed(1)}M';
    } else if (price >= 1000) {
      return '\$${(price / 1000).toStringAsFixed(0)}K';
    } else {
      return '\$${price.toStringAsFixed(0)}';
    }
  }

  /// Formatted area string
  String get formattedArea {
    return '${area.toStringAsFixed(0)} sq ft';
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