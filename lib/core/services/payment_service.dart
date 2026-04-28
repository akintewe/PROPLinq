import '../constants/api_constants.dart';
import 'api_service.dart';

enum PaymentType {
  propertyPurchase,
  rentPayment,
  subscription,
  walletTopup;

  String get value {
    switch (this) {
      case PaymentType.propertyPurchase:
        return 'property_purchase';
      case PaymentType.rentPayment:
        return 'rent_payment';
      case PaymentType.subscription:
        return 'subscription';
      case PaymentType.walletTopup:
        return 'wallet_deposit';
    }
  }
}

class PaymentInitResponse {
  final String? authorizationUrl;
  final String? reference;
  final Map<String, dynamic> raw;

  PaymentInitResponse({
    required this.authorizationUrl,
    this.reference,
    required this.raw,
  });

  factory PaymentInitResponse.fromJson(Map<String, dynamic> json) {
    final data = json['data'] is Map<String, dynamic>
        ? json['data'] as Map<String, dynamic>
        : json;

    final url = data['authorization_url']?.toString() ??
        data['link']?.toString() ??
        data['payment_url']?.toString() ??
        data['checkout_url']?.toString();

    return PaymentInitResponse(
      authorizationUrl: url,
      reference: data['reference']?.toString() ?? data['tx_ref']?.toString(),
      raw: data,
    );
  }
}

class PaymentService {
  static final PaymentService _instance = PaymentService._internal();
  factory PaymentService() => _instance;
  PaymentService._internal();

  final ApiService _api = ApiService();

  Future<ApiResponse<PaymentInitResponse>> initialize({
    required double amount,
    required PaymentType type,
    Map<String, dynamic>? meta,
    String? provider,
  }) async {
    final body = <String, dynamic>{
      'amount': amount,
      'type': type.value,
      if (meta != null) 'meta': meta,
      if (provider != null) 'provider': provider,
    };

    final response = await _api.post<PaymentInitResponse>(
      ApiConstants.initializePayment,
      body: body,
      requiresAuth: true,
      fromJson: (json) => PaymentInitResponse.fromJson(json),
    );

    return response;
  }

  Future<ApiResponse<Map<String, dynamic>>> verify({String? reference}) async {
    final body = <String, dynamic>{
      if (reference != null) 'reference': reference,
    };

    final response = await _api.post<Map<String, dynamic>>(
      ApiConstants.verifyPayment,
      body: body,
      requiresAuth: true,
      fromJson: (json) => json as Map<String, dynamic>? ?? {},
    );

    return response;
  }

  Future<ApiResponse<List<Map<String, dynamic>>>> listTransactions() async {
    final response = await _api.get<List<Map<String, dynamic>>>(
      ApiConstants.listTransactions,
      requiresAuth: true,
      fromJson: (json) {
        final dynamic raw = json;
        final List<dynamic> list;
        if (raw is List) {
          list = raw;
        } else if (raw is Map<String, dynamic>) {
          final inner = raw['data'] ?? raw['transactions'] ?? const <dynamic>[];
          list = inner is List ? inner : [];
        } else {
          list = [];
        }
        return list.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      },
    );

    return response;
  }
}
