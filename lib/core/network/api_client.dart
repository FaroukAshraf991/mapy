import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'api_response.dart';

/// Base HTTP client with common configuration and error handling
class ApiClient {
  final String baseUrl;
  final Map<String, String> defaultHeaders;
  final Duration timeout;

  ApiClient({
    required this.baseUrl,
    this.defaultHeaders = const {},
    this.timeout = const Duration(seconds: 30),
  });

  /// Perform a GET request
  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    return _request<T>(
      method: 'GET',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      parser: parser,
    );
  }

  /// Perform a POST request
  Future<ApiResponse<T>> post<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    return _request<T>(
      method: 'POST',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      parser: parser,
    );
  }

  /// Perform a PUT request
  Future<ApiResponse<T>> put<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    return _request<T>(
      method: 'PUT',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      body: body,
      parser: parser,
    );
  }

  /// Perform a DELETE request
  Future<ApiResponse<T>> delete<T>(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    T Function(dynamic json)? parser,
  }) async {
    return _request<T>(
      method: 'DELETE',
      path: path,
      headers: headers,
      queryParameters: queryParameters,
      parser: parser,
    );
  }

  /// Core request method with error handling
  Future<ApiResponse<T>> _request<T>({
    required String method,
    required String path,
    Map<String, String>? headers,
    Map<String, dynamic>? queryParameters,
    dynamic body,
    T Function(dynamic json)? parser,
  }) async {
    try {
      final uri = Uri.parse('$baseUrl$path').replace(
        queryParameters: queryParameters,
      );

      final mergedHeaders = {...defaultHeaders, ...?headers};

      // Log request in debug mode
      if (kDebugMode) {
        debugPrint('🌐 $method $uri');
        if (body != null) debugPrint('📤 Body: $body');
      }

      late http.Response response;

      switch (method) {
        case 'GET':
          response =
              await http.get(uri, headers: mergedHeaders).timeout(timeout);
          break;
        case 'POST':
          response = await http
              .post(uri, headers: mergedHeaders, body: jsonEncode(body))
              .timeout(timeout);
          break;
        case 'PUT':
          response = await http
              .put(uri, headers: mergedHeaders, body: jsonEncode(body))
              .timeout(timeout);
          break;
        case 'DELETE':
          response =
              await http.delete(uri, headers: mergedHeaders).timeout(timeout);
          break;
        default:
          throw Exception('Unsupported HTTP method: $method');
      }

      // Log response in debug mode
      if (kDebugMode) {
        debugPrint('📥 Status: ${response.statusCode}');
        debugPrint(
            '📥 Body: ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}...');
      }

      return _handleResponse<T>(response, parser);
    } catch (e) {
      if (kDebugMode) {
        debugPrint('❌ API Error: $e');
      }
      return ApiResponse.error(_formatError(e));
    }
  }

  /// Parse and handle the HTTP response
  ApiResponse<T> _handleResponse<T>(
    http.Response response,
    T Function(dynamic json)? parser,
  ) {
    final statusCode = response.statusCode;

    if (statusCode >= 200 && statusCode < 300) {
      if (response.body.isEmpty) {
        return ApiResponse.success(null as T, statusCode: statusCode);
      }

      try {
        final json = jsonDecode(response.body);
        final data = parser != null ? parser(json) : json as T;
        return ApiResponse.success(data, statusCode: statusCode);
      } catch (e) {
        return ApiResponse.error('Failed to parse response: $e',
            statusCode: statusCode);
      }
    } else {
      return ApiResponse.error(
        _getErrorMessage(response),
        statusCode: statusCode,
      );
    }
  }

  /// Extract error message from response
  String _getErrorMessage(http.Response response) {
    try {
      final json = jsonDecode(response.body);
      if (json is Map<String, dynamic>) {
        return json['message'] ??
            json['error'] ??
            json['msg'] ??
            'Request failed with status ${response.statusCode}';
      }
    } catch (_) {}
    return 'Request failed with status ${response.statusCode}';
  }

  /// Format exception to user-friendly message
  String _formatError(dynamic error) {
    if (error is Exception) {
      final message = error.toString();
      if (message.contains('TimeoutException')) {
        return 'Request timed out. Please try again.';
      }
      if (message.contains('SocketException')) {
        return 'No internet connection. Please check your network.';
      }
    }
    return 'An unexpected error occurred. Please try again.';
  }
}
