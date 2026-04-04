import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

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
      // Handle empty or whitespace-only responses (common for DELETE requests)
      final body = response.body.trim();
      if (body.isEmpty) {
        if (response.statusCode >= 200 && response.statusCode < 300) {
          // Empty successful response (e.g., 204 No Content)
          return ApiResponse.success(
            data: null,
            message: 'Success',
            statusCode: response.statusCode,
          );
        } else {
          // Empty error response
          return ApiResponse.error(
            message: 'An error occurred',
            statusCode: response.statusCode,
          );
        }
      }
      
      final Map<String, dynamic> jsonData = json.decode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        // Success response
        T? data;
        if (jsonData.containsKey('data') && jsonData['data'] != null) {
          // Check if data is a Map (expected format for fromJson)
          if (jsonData['data'] is Map<String, dynamic>) {
            data = fromJson(jsonData['data']);
          } else if (jsonData['data'] is List) {
            // If data is a List, we need to handle it specially
            // For generic T, we'll pass the whole jsonData so fromJson can extract the list
            // This is typically used when T is dynamic or when the fromJson handles the extraction
            try {
              data = fromJson(jsonData);
            } catch (e) {
              // If that fails, try passing just the data list wrapped in a map
              data = fromJson({'data': jsonData['data']});
            }
          } else {
            // If data is not a Map or List, pass empty Map to fromJson
            data = fromJson({});
          }
        } else {
          // No 'data' key, pass the whole jsonData
          data = fromJson(jsonData);
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
          final errorList = <String>[];
          final rawErrors = jsonData['errors'];
          if (rawErrors is Map) {
            rawErrors.forEach((key, value) {
              if (value is List) {
                errorList.addAll(value.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty));
              } else if (value != null) {
                errorList.add(value.toString());
              }
            });
          } else if (rawErrors is List) {
            errorList.addAll(rawErrors.map((e) => e?.toString() ?? '').where((s) => s.isNotEmpty));
          } else if (rawErrors != null) {
            errorList.add(rawErrors.toString());
          }
          errors = errorList;
        }
        
        return ApiResponse.error(
          message: message,
          errors: errors,
          statusCode: response.statusCode,
        );
      }
    } catch (e) {
      // If JSON parsing fails but status code is success, treat as success
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return ApiResponse.success(
          data: null,
          message: 'Success',
          statusCode: response.statusCode,
        );
      }
      return ApiResponse.error(
        message: 'An error occurred while processing the server response. Please try again.',
        statusCode: response.statusCode,
      );
    }
  }

  // Generic GET request
  Future<ApiResponse<T>> get<T>(
    String endpoint, {
    Map<String, String>? queryParams,
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      String urlString = _buildUrl(endpoint);
      
      // Add query parameters if provided
      if (queryParams != null && queryParams.isNotEmpty) {
        final uri = Uri.parse(urlString);
        final queryParameters = Map<String, String>.from(uri.queryParameters);
        queryParameters.addAll(queryParams);
        
        urlString = uri.replace(queryParameters: queryParameters).toString();
      }
      
      final url = Uri.parse(urlString);
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      final response = await _client.get(url, headers: headers);
      
      if (fromJson != null) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleResponse<T>(response, (json) => json as T);
      }
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on http.ClientException catch (_) {
      return ApiResponse.error(
        message: 'Unable to connect to the server. Please check your internet connection and try again.',
        statusCode: 0,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'An error occurred while processing your request. Please try again.',
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
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on http.ClientException catch (_) {
      return ApiResponse.error(
        message: 'Unable to connect to the server. Please check your internet connection and try again.',
        statusCode: 0,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'An error occurred while processing your request. Please try again.',
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
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on http.ClientException catch (_) {
      return ApiResponse.error(
        message: 'Unable to connect to the server. Please check your internet connection and try again.',
        statusCode: 0,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'An error occurred while processing your request. Please try again.',
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
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on http.ClientException catch (_) {
      return ApiResponse.error(
        message: 'Unable to connect to the server. Please check your internet connection and try again.',
        statusCode: 0,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'An error occurred while processing your request. Please try again.',
        statusCode: 0,
      );
    }
  }

  // Form data POST request for file uploads
  Future<ApiResponse<T>> postFormData<T>(
    String endpoint, {
    required Map<String, String> fields,
    required Map<String, File> files,
    bool requiresAuth = false,
    T Function(Map<String, dynamic>)? fromJson,
  }) async {
    try {
      final url = Uri.parse(_buildUrl(endpoint));
      final headers = await _buildHeaders(requiresAuth: requiresAuth);
      
      // Remove Content-Type header for multipart request
      headers.remove('Content-Type');
      
      // Create multipart request
      final request = http.MultipartRequest('POST', url);
      
      // Add headers
      request.headers.addAll(headers);
      
      // Add text fields
      request.fields.addAll(fields);
      
      // Add files
      for (final entry in files.entries) {
        final file = entry.value;
        final fieldName = entry.key;
        
        if (await file.exists()) {
          final stream = http.ByteStream(file.openRead());
          final length = await file.length();
          
          final multipartFile = http.MultipartFile(
            fieldName,
            stream,
            length,
            filename: file.path.split('/').last,
          );
          
          request.files.add(multipartFile);
        }
      }
      
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      
      if (fromJson != null) {
        return _handleResponse(response, fromJson);
      } else {
        return _handleResponse<T>(response, (json) => json as T);
      }
    } on SocketException catch (_) {
      return ApiResponse.error(
        message: 'No internet connection. Please check your network and try again.',
        statusCode: 0,
      );
    } on http.ClientException catch (_) {
      return ApiResponse.error(
        message: 'Unable to connect to the server. Please check your internet connection and try again.',
        statusCode: 0,
      );
    } catch (_) {
      return ApiResponse.error(
        message: 'An error occurred while processing your request. Please try again.',
        statusCode: 0,
      );
    }
  }

  // Dispose method
  void dispose() {
    _client.close();
  }
} 