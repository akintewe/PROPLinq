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
    final currentPage = json['current_page'] as int? ?? 1;
    final lastPage = json['last_page'] as int? ?? 1;

    return PaginatedPropertiesResponse(
      properties: json['data'] as List<dynamic>? ?? [],
      currentPage: currentPage,
      lastPage: lastPage,
      total: json['total'] as int? ?? 0,
      perPage: json['per_page'] as int? ?? 15,
      hasMorePages: currentPage < lastPage,
      nextPageUrl: json['next_page_url'] as String?,
      prevPageUrl: json['prev_page_url'] as String?,
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
        .map((json) => fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  String toString() {
    return 'PaginatedPropertiesResponse(currentPage: $currentPage, lastPage: $lastPage, total: $total, itemsInPage: ${properties.length}, hasMorePages: $hasMorePages)';
  }
}
