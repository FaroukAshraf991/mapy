import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Abstract interceptor for HTTP requests and responses
abstract class HttpInterceptor {
  /// Called before the request is sent
  Future<http.BaseRequest> onRequest(http.BaseRequest request) async {
    return request;
  }

  /// Called after the response is received
  Future<http.Response> onResponse(http.Response response) async {
    return response;
  }

  /// Called when an error occurs
  Future<void> onError(dynamic error, StackTrace stackTrace) async {}
}

/// Logging interceptor for debugging
class LoggingInterceptor extends HttpInterceptor {
  @override
  Future<http.BaseRequest> onRequest(http.BaseRequest request) async {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────');
      debugPrint('│ 🌐 ${request.method} ${request.url}');
      debugPrint('│ Headers: ${request.headers}');
      if (request is http.Request && request.body.isNotEmpty) {
        debugPrint('│ Body: ${request.body}');
      }
      debugPrint('└──────────────────────────────────────────');
    }
    return request;
  }

  @override
  Future<http.Response> onResponse(http.Response response) async {
    if (kDebugMode) {
      final statusEmoji = response.statusCode < 300 ? '✅' : '❌';
      debugPrint('┌──────────────────────────────────────────');
      debugPrint(
          '│ $statusEmoji ${response.statusCode} ${response.request?.url}');
      final bodyPreview = response.body.length > 500
          ? '${response.body.substring(0, 500)}...'
          : response.body;
      debugPrint('│ Response: $bodyPreview');
      debugPrint('└──────────────────────────────────────────');
    }
    return response;
  }

  @override
  Future<void> onError(dynamic error, StackTrace stackTrace) async {
    if (kDebugMode) {
      debugPrint('┌──────────────────────────────────────────');
      debugPrint('│ ❌ HTTP Error');
      debugPrint('│ $error');
      debugPrint('│ $stackTrace');
      debugPrint('└──────────────────────────────────────────');
    }
  }
}

/// Auth interceptor for adding auth headers
class AuthInterceptor extends HttpInterceptor {
  final String? Function()? tokenProvider;

  AuthInterceptor({this.tokenProvider});

  @override
  Future<http.BaseRequest> onRequest(http.BaseRequest request) async {
    final token = tokenProvider?.call();
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }
    return request;
  }
}

/// Retry interceptor for failed requests
class RetryInterceptor extends HttpInterceptor {
  final int maxRetries;
  final Duration retryDelay;

  RetryInterceptor({
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });

  @override
  Future<http.Response> onResponse(http.Response response) async {
    // If rate limited, wait and retry
    if (response.statusCode == 429) {
      final retryAfter = response.headers['retry-after'];
      final delay = retryAfter != null
          ? Duration(seconds: int.tryParse(retryAfter) ?? 1)
          : retryDelay;

      if (kDebugMode) {
        debugPrint('⏳ Rate limited. Retrying after ${delay.inSeconds}s');
      }

      await Future.delayed(delay);
    }
    return response;
  }
}

/// Error handling interceptor
class ErrorInterceptor extends HttpInterceptor {
  @override
  Future<http.Response> onResponse(http.Response response) async {
    if (response.statusCode >= 400) {
      final body = _tryParseJson(response.body);
      final message = body?['message'] ??
          body?['error'] ??
          body?['msg'] ??
          'Request failed with status ${response.statusCode}';

      if (kDebugMode) {
        debugPrint('❌ API Error: $message');
      }
    }
    return response;
  }

  Map<String, dynamic>? _tryParseJson(String body) {
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }
}
