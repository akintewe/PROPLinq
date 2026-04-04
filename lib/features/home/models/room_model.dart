String _toTitleCase(String s) => s
    .split(' ')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

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
    double parsePrice(dynamic v) {
      if (v is num) return v.toDouble();
      if (v is String) return double.tryParse(v) ?? 0.0;
      return 0.0;
    }

    int parseInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? 0;
      return 0;
    }

    return RoomModel(
      id: json['id'] == null ? null : parseInt(json['id']),
      uuid: json['uuid']?.toString(),
      name: _toTitleCase(json['custom_name']?.toString() ?? json['proplinq_name']?.toString() ?? json['name']?.toString() ?? ''),
      type: json['type']?.toString() ?? '',
      price: parsePrice(json['price']),
      capacity: parseInt(json['capacity']),
      count: parseInt(json['count']),
      features: json['features'] is List
          ? (json['features'] as List).map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty).toList()
          : [],
      imageUrl: json['image_url']?.toString() ??
          (json['images'] is List && (json['images'] as List).isNotEmpty
              ? (json['images'] as List).first is Map
                  ? ((json['images'] as List).first as Map)['url']?.toString()
                  : null
              : null),
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
