/// Type-safe base response model for all API responses
/// Generic T allows for proper type safety while maintaining flexibility
class BaseResponse<T> {
  final int statusCode;
  final bool success;
  final String? message;
  final T? data;
  final Map<String, dynamic>? meta;

  const BaseResponse({
    required this.statusCode,
    required this.success,
    this.message,
    this.data,
    this.meta,
  });

  /// Check if the response indicates success
  bool get isSuccess => success && statusCode >= 200 && statusCode < 300;

  /// Check if the response has data
  bool get hasData => data != null;

  /// Get error message with fallback
  String get errorMessage => message ?? 'Unknown error occurred';
}
