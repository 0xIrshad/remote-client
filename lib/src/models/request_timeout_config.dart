import 'package:dio/dio.dart';

/// Configuration for per-request timeouts
/// Allows overriding global timeout settings for specific requests
class RequestTimeoutConfig {
  /// Send timeout - time to send data to server
  final Duration? sendTimeout;

  /// Receive timeout - time to receive data from server
  final Duration? receiveTimeout;

  const RequestTimeoutConfig({this.sendTimeout, this.receiveTimeout});

  /// Create timeout config from milliseconds
  factory RequestTimeoutConfig.fromMilliseconds({
    int? sendTimeoutMs,
    int? receiveTimeoutMs,
  }) {
    return RequestTimeoutConfig(
      sendTimeout: sendTimeoutMs != null
          ? Duration(milliseconds: sendTimeoutMs)
          : null,
      receiveTimeout: receiveTimeoutMs != null
          ? Duration(milliseconds: receiveTimeoutMs)
          : null,
    );
  }

  /// Create timeout config for quick operations (short timeouts)
  static const RequestTimeoutConfig quick = RequestTimeoutConfig(
    sendTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
  );

  /// Create timeout config for normal operations (default timeouts)
  static const RequestTimeoutConfig normal = RequestTimeoutConfig();

  /// Create timeout config for long operations (extended timeouts)
  static const RequestTimeoutConfig extended = RequestTimeoutConfig(
    sendTimeout: Duration(seconds: 120),
    receiveTimeout: Duration(seconds: 120),
  );

  /// Create timeout config for file uploads (long send timeout)
  static const RequestTimeoutConfig fileUpload = RequestTimeoutConfig(
    sendTimeout: Duration(seconds: 300),
    receiveTimeout: Duration(seconds: 30),
  );

  /// Create timeout config for file downloads (long receive timeout)
  static const RequestTimeoutConfig fileDownload = RequestTimeoutConfig(
    sendTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 300),
  );

  /// Merges this timeout config with provided Options
  /// Returns new Options with timeouts merged
  Options mergeWithOptions(Options? existingOptions) {
    final options = existingOptions ?? Options();
    return Options(
      method: options.method,
      sendTimeout: sendTimeout ?? options.sendTimeout,
      receiveTimeout: receiveTimeout ?? options.receiveTimeout,
      extra: options.extra,
      headers: options.headers,
      responseType: options.responseType,
      validateStatus: options.validateStatus,
      receiveDataWhenStatusError: options.receiveDataWhenStatusError,
      followRedirects: options.followRedirects,
      maxRedirects: options.maxRedirects,
      requestEncoder: options.requestEncoder,
      responseDecoder: options.responseDecoder,
      listFormat: options.listFormat,
      contentType: options.contentType,
    );
  }
}
