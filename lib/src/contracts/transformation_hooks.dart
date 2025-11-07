import 'package:dio/dio.dart';

/// Hook for transforming request data before sending
/// Useful for encryption, data formatting, or adding computed fields
typedef RequestTransformHook =
    dynamic Function(String endpoint, dynamic data, RequestOptions options);

/// Hook for transforming response data before parsing
/// Useful for decryption, data normalization, or extracting nested data
typedef ResponseTransformHook =
    dynamic Function(String endpoint, Response response);

/// Combined transformation hooks for request and response
/// Both hooks are optional - provide only what you need
class TransformationHooks {
  /// Transform request data before sending
  /// Receives: endpoint, data, and request options
  /// Returns: transformed data (can be Map, List, String, etc.)
  final RequestTransformHook? onRequestTransform;

  /// Transform response data before parsing
  /// Receives: endpoint and Dio response
  /// Returns: transformed response data
  final ResponseTransformHook? onResponseTransform;

  const TransformationHooks({
    this.onRequestTransform,
    this.onResponseTransform,
  });

  /// Empty hooks (no transformations)
  const TransformationHooks.empty()
    : onRequestTransform = null,
      onResponseTransform = null;

  /// Create hooks with only request transformation
  TransformationHooks.requestOnly(this.onRequestTransform)
    : onResponseTransform = null;

  /// Create hooks with only response transformation
  TransformationHooks.responseOnly(this.onResponseTransform)
    : onRequestTransform = null;
}
