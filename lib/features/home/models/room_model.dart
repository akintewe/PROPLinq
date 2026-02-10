/// Room model for hotel rooms
class RoomModel {
  final int? id;
  final String? uuid;
  final String name;
  final String type;
  final double price;
  final int capacity;
  final int count;
  final List<String> features;
  final String? imageUrl;

  const RoomModel({
    this.id,
    this.uuid,
    required this.name,
    required this.type,
    required this.price,
    required this.capacity,
    required this.count,
    required this.features,
    this.imageUrl,
  });

  factory RoomModel.fromJson(Map<String, dynamic> json) {
    // Handle price - could be string or number from API
    double parsePrice(dynamic priceValue) {
      if (priceValue is num) {
        return priceValue.toDouble();
      } else if (priceValue is String) {
        return double.parse(priceValue);
      }
      return 0.0;
    }

    return RoomModel(
      id: json['id'] as int?,
      uuid: json['uuid'] as String?,
      name: json['name'] as String,
      type: json['type'] as String,
      price: parsePrice(json['price']),
      capacity: json['capacity'] as int,
      count: json['count'] as int,
      features: (json['features'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      imageUrl: json['image_url'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      if (uuid != null) 'uuid': uuid,
      'name': name,
      'type': type,
      'price': price,
      'capacity': capacity,
      'count': count,
      'features': features,
      if (imageUrl != null) 'image_url': imageUrl,
    };
  }

  /// Create from CSV row (name, type, price, capacity, count, features)
  /// Features are separated by pipe '|' in the CSV
  factory RoomModel.fromCsvRow(List<String> row) {
    if (row.length < 6) {
      throw ArgumentError('CSV row must have at least 6 columns');
    }

    return RoomModel(
      name: row[0].trim(),
      type: row[1].trim(),
      price: double.parse(row[2].trim()),
      capacity: int.parse(row[3].trim()),
      count: int.parse(row[4].trim()),
      features: row[5]
          .trim()
          .split('|')
          .map((f) => f.trim())
          .where((f) => f.isNotEmpty)
          .toList(),
    );
  }

  /// Convert to CSV row string
  String toCsvRow() {
    return '$name,$type,$price,$capacity,$count,"${features.join(',')}"';
  }

  @override
  String toString() {
    return 'RoomModel(id: $id, uuid: $uuid, name: $name, type: $type, price: $price, capacity: $capacity, count: $count, features: $features, imageUrl: $imageUrl)';
  }
}
