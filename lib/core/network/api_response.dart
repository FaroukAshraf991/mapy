/// Unified API response wrapper for consistent error handling
class ApiResponse<T> {
  final T? data;
  final String? error;
  final int? statusCode;
  final bool success;

  const ApiResponse._({
    this.data,
    this.error,
    this.statusCode,
    required this.success,
  });

  /// Create a successful response
  factory ApiResponse.success(T data, {int? statusCode}) {
    return ApiResponse._(
      data: data,
      statusCode: statusCode ?? 200,
      success: true,
    );
  }

  /// Create an error response
  factory ApiResponse.error(String message, {int? statusCode}) {
    return ApiResponse._(
      error: message,
      statusCode: statusCode,
      success: false,
    );
  }

  /// Whether the response has data
  bool get hasData => data != null;

  /// Whether the response has an error
  bool get hasError => error != null;

  @override
  String toString() {
    if (success) {
      return 'ApiResponse.success(data: $data, statusCode: $statusCode)';
    }
    return 'ApiResponse.error(error: $error, statusCode: $statusCode)';
  }
}
