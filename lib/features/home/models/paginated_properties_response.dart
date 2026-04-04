class PaginatedPropertiesResponse {
  final List<dynamic> properties;
  final int currentPage;
  final int lastPage;
  final int total;
  final int perPage;
  final bool hasMorePages;
  final String? nextPageUrl;
  final String? prevPageUrl;

  PaginatedPropertiesResponse({
    required this.properties,
    required this.currentPage,
    required this.lastPage,
    required this.total,
    required this.perPage,
    required this.hasMorePages,
    this.nextPageUrl,
    this.prevPageUrl,
  });

  factory PaginatedPropertiesResponse.fromJson(Map<String, dynamic> json) {
    int parseInt(dynamic v, int fallback) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v) ?? fallback;
      return fallback;
    }

    final currentPage = parseInt(json['current_page'], 1);
    final lastPage = parseInt(json['last_page'], 1);
    final rawData = json['data'];

    return PaginatedPropertiesResponse(
      properties: rawData is List ? rawData : [],
      currentPage: currentPage,
      lastPage: lastPage,
      total: parseInt(json['total'], 0),
      perPage: parseInt(json['per_page'], 15),
      hasMorePages: currentPage < lastPage,
      nextPageUrl: json['next_page_url']?.toString(),
      prevPageUrl: json['prev_page_url']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'data': properties,
      'current_page': currentPage,
      'last_page': lastPage,
      'total': total,
      'per_page': perPage,
      'has_more_pages': hasMorePages,
      'next_page_url': nextPageUrl,
      'prev_page_url': prevPageUrl,
    };
  }

  /// Convert properties data to PropertyModel list
  List<T> getPropertiesAs<T>(T Function(Map<String, dynamic>) fromJson) {
    return properties
        .whereType<Map>()
        .map((json) {
          try {
            return fromJson(Map<String, dynamic>.from(json));
          } catch (_) {
            return null;
          }
        })
        .whereType<T>()
        .toList();
  }

  @override
  String toString() {
    return 'PaginatedPropertiesResponse(currentPage: $currentPage, lastPage: $lastPage, total: $total, itemsInPage: ${properties.length}, hasMorePages: $hasMorePages)';
  }
}
