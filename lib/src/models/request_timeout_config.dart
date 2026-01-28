import 'package:dio/dio.dart';

/// Configuration for per-request timeouts
/// Allows overriding global timeout settings for specific requests
class RequestTimeoutConfig {
  /// Connect timeout - time to establish a connection to the server
  final Duration? connectTimeout;

  /// Send timeout - time to send data to server
  final Duration? sendTimeout;

  /// Receive timeout - time to receive data from server
  final Duration? receiveTimeout;

  const RequestTimeoutConfig({
    this.connectTimeout,
    this.sendTimeout,
    this.receiveTimeout,
  });

  /// Create timeout config from milliseconds
  factory RequestTimeoutConfig.fromMilliseconds({
    int? connectTimeoutMs,
    int? sendTimeoutMs,
    int? receiveTimeoutMs,
  }) {
    return RequestTimeoutConfig(
      connectTimeout: connectTimeoutMs != null ? Duration(milliseconds: connectTimeoutMs) : null,
      sendTimeout: sendTimeoutMs != null ? Duration(milliseconds: sendTimeoutMs) : null,
      receiveTimeout: receiveTimeoutMs != null ? Duration(milliseconds: receiveTimeoutMs) : null,
    );
  }

  /// Create timeout config for quick operations (short timeouts)
  static const RequestTimeoutConfig quick = RequestTimeoutConfig(
    connectTimeout: Duration(seconds: 5),
    sendTimeout: Duration(seconds: 5),
    receiveTimeout: Duration(seconds: 5),
  );

  /// Create timeout config for normal operations (default timeouts)
  static const RequestTimeoutConfig normal = RequestTimeoutConfig();

  /// Create timeout config for long operations (extended timeouts)
  static const RequestTimeoutConfig extended = RequestTimeoutConfig(
    connectTimeout: Duration(seconds: 60),
    sendTimeout: Duration(seconds: 120),
    receiveTimeout: Duration(seconds: 120),
  );

  /// Create timeout config for file uploads (long send timeout)
  static const RequestTimeoutConfig fileUpload = RequestTimeoutConfig(
    connectTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 300),
    receiveTimeout: Duration(seconds: 30),
  );

  /// Create timeout config for file downloads (long receive timeout)
  static const RequestTimeoutConfig fileDownload = RequestTimeoutConfig(
    connectTimeout: Duration(seconds: 30),
    sendTimeout: Duration(seconds: 30),
    receiveTimeout: Duration(seconds: 300),
  );

  /// Create timeout config for slow connections (extended connect timeout)
  static const RequestTimeoutConfig slowConnection = RequestTimeoutConfig(
    connectTimeout: Duration(seconds: 60),
    sendTimeout: Duration(seconds: 60),
    receiveTimeout: Duration(seconds: 60),
  );

  /// Merges this timeout config with provided Options
  /// Returns new Options with timeouts merged
  /// Note: Dio Options doesn't have connectTimeout, so it's applied at BaseOptions level
  Options mergeWithOptions(Options? existingOptions) {
    final Options options = existingOptions ?? Options();
    return Options(
      method: options.method,
      sendTimeout: sendTimeout ?? options.sendTimeout,
      receiveTimeout: receiveTimeout ?? options.receiveTimeout,
      extra: _mergeConnectTimeoutIntoExtra(options.extra),
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

  /// Merge connectTimeout into extra for per-request handling
  /// The RemoteClientImpl can read this and apply it to the request
  Map<String, dynamic>? _mergeConnectTimeoutIntoExtra(Map<String, dynamic>? existingExtra) {
    if (connectTimeout == null) {
      return existingExtra;
    }
    return <String, dynamic>{
      ...?existingExtra,
      '_connectTimeout': connectTimeout,
    };
  }

  /// Get connectTimeout from Options extra if set
  static Duration? getConnectTimeoutFromOptions(Options? options) {
    return options?.extra?['_connectTimeout'] as Duration?;
  }
}
