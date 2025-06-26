import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/api_constants.dart';
import 'storage_service.dart';

class ApiResponse<T> {
  final bool success;
  final T? data;
  final String? message;
  final List<String>? errors;
  final int? statusCode;

  ApiResponse({
    required this.success,
    this.data,
    this.message,
    this.errors,
    this.statusCode,
  });

  factory ApiResponse.success({T? data, String? message, int? statusCode}) {
    return ApiResponse<T>(
      success: true,
      data: data,
      message: message,
      statusCode: statusCode,
    );
  }

  factory ApiResponse.error({
    String? message,
    List<String>? errors,
    int? statusCode,
  }) {
    return ApiResponse<T>(
      success: false,
      message: message,
      errors: errors,
      statusCode: statusCode,
    );
  }
}

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal();

  final http.Client _client = http.Client();
  final StorageService _storageService = StorageService();

  // Get authentication token
  Future<String?> _getAuthToken() async {
    return await _storageService.getToken();
  }

  // Build full URL
  String _buildUrl(String endpoint) {
    return ApiConstants.apiBaseUrl + endpoint;
  }

  // Build headers
  Future<Map<String, String>> _buildHeaders({bool requiresAuth = false}) async {
    Map<String, String> headers = Map.from(ApiConstants.defaultHeaders);
    
    if (requiresAuth) {
      final token = await _getAuthToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    
    return headers;
  }

  // Handle API response
  ApiResponse<T> _handleResponse<T>(http.Response response, T Function(Map<String, dynamic>) fromJson) {
    try {
      print('🌐 Raw API Response Body: ${response.body}');
      final Map<String, dynamic> jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response
        T? data;
        if (jsonData.containsKey('data') && jsonData['data'] != null) {
          // Check if data is a Map (expected format for fromJson)
          if (jsonData['data'] is Map<String, dynamic>) {
            data = fromJson(jsonData['data']);
          } else {
            // If data is not a Map (e.g., array), pass empty Map to fromJson
            data = fromJson({});
          }
        }
        
        return ApiResponse.success(
          data: data,
          message: jsonData['message'] ?? 'Success',
          statusCode: response.statusCode,
        );
      } else {
        // Error response
        List<String>? errors;
        String? message = jsonData['message'] ?? 'An error occurred';
        
        if (jsonData.containsKey('errors')) {
          if (jsonData['errors'] is Map) {
            // Validation errors
            errors = [];
            (jsonData['errors'] as Map).forEach((key, value) {
              if (value is List) {
                errors!.addAll(value.cast<String>());
              } else {
                errors!.add(value.toString());
              }
            });
          } else if (jsonData['errors'] is List) {
            errors = (jsonData['errors'] as List).cast<String>();
          }
        }
        
        return ApiResponse.error(
          message: message,
          errors: errors,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      return ApiResponse.error(
        message: 'Failed to parse response: $e',
        statusCode: response.statusCode,
      );
    }
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      final response = await _client.get(url, headers: headers);
      
      if (fromJson != null) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleResponse<T>(response, (json) => json as T);
      }
    } on SocketException {
      return ApiResponse.error(
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Request failed: $e',
        statusCode: 0,
      );
    }
  }

  // Generic POST request
  Future<ApiResponse<T>> post<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      final response = await _client.post(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      if (fromJson != null) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleResponse<T>(response, (json) => json as T);
      }
    } on SocketException {
      return ApiResponse.error(
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Request failed: $e',
        statusCode: 0,
      );
    }
  }

  // Generic PUT request
  Future<ApiResponse<T>> put<T>(
    String endpoint, {
    Map<String, dynamic>? body,
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      final response = await _client.put(
        url,
        headers: headers,
        body: body != null ? json.encode(body) : null,
      );
      
      if (fromJson != null) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleResponse<T>(response, (json) => json as T);
      }
    } on SocketException {
      return ApiResponse.error(
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Request failed: $e',
        statusCode: 0,
      );
    }
  }

  // Generic DELETE request
  Future<ApiResponse<T>> delete<T>(
    String endpoint, {
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      final response = await _client.delete(url, headers: headers);
      
      if (fromJson != null) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleResponse<T>(response, (json) => json as T);
      }
    } on SocketException {
      return ApiResponse.error(
        message: 'No internet connection',
        statusCode: 0,
      );
    } catch (e) {
      return ApiResponse.error(
        message: 'Request failed: $e',
        statusCode: 0,
      );
    }
  }

  // Dispose method
  void dispose() {
    _client.close();
  }
} 