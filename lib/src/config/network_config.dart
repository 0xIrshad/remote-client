/// Network configuration for Dio client setup
/// Performance-optimized defaults
class NetworkConfig {
  /// Base URL for API requests
  final String baseUrl;

  /// Connection timeout - time to establish a connection
  final Duration connectTimeout;

  /// Receive timeout - time to receive data from server
  final Duration receiveTimeout;

  /// Send timeout - time to send data to server
  final Duration sendTimeout;

  /// Default headers for all requests
  final Map<String, String> defaultHeaders;

  /// Maximum number of connections per host
  /// Default: 5 (good balance for mobile apps)
  final int maxConnectionsPerHost;

  /// Enable HTTP/2 if supported
  final bool enableHttp2;

  const NetworkConfig({
    required this.baseUrl,
    this.connectTimeout = const Duration(seconds: 60),
    this.receiveTimeout = const Duration(seconds: 60),
    this.sendTimeout = const Duration(seconds: 60),
    this.defaultHeaders = const {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    },
    this.maxConnectionsPerHost = 5,
    this.enableHttp2 = true,
  });

  /// Create config with custom timeouts
  NetworkConfig copyWith({
    String? baseUrl,
    Duration? connectTimeout,
    Duration? receiveTimeout,
    Duration? sendTimeout,
    Map<String, String>? defaultHeaders,
    int? maxConnectionsPerHost,
    bool? enableHttp2,
  }) {
    return NetworkConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      connectTimeout: connectTimeout ?? this.connectTimeout,
      receiveTimeout: receiveTimeout ?? this.receiveTimeout,
      sendTimeout: sendTimeout ?? this.sendTimeout,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      maxConnectionsPerHost:
          maxConnectionsPerHost ?? this.maxConnectionsPerHost,
      enableHttp2: enableHttp2 ?? this.enableHttp2,
    );
  }
}
