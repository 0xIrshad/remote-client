import 'package:dio/dio.dart';

import 'package:remote_client/src/config/network_config.dart';
import 'package:remote_client/src/contracts/error_handler.dart';
import 'package:remote_client/src/contracts/response_parser.dart';
import 'package:remote_client/src/contracts/token_provider.dart';
import 'package:remote_client/src/contracts/transformation_hooks.dart';
import 'package:remote_client/src/contracts/unauthorized_handler.dart';
import 'package:remote_client/src/interceptors/auth_interceptor.dart';
import 'package:remote_client/src/interceptors/cache_interceptor.dart';
import 'package:remote_client/src/interceptors/deduplication_interceptor.dart';
import 'package:remote_client/src/interceptors/dio_logger.dart';
import 'package:remote_client/src/interceptors/retry_interceptor.dart';
import 'package:remote_client/src/interceptors/transformation_interceptor.dart';
import 'package:remote_client/src/models/retry_policy.dart';
import 'package:remote_client/src/remote_client_impl.dart';
import 'package:remote_client/src/services/error_handler_impl.dart';
import 'package:remote_client/src/services/response_parser_impl.dart';

/// Factory for creating RemoteClient instances
/// Performance-optimized with connection pooling and efficient defaults
class RemoteClientFactory {
  /// Create a RemoteClient with minimal configuration
  /// Uses sensible defaults for performance
  static RemoteClientImpl create({
    required String baseUrl,
    NetworkConfig? networkConfig,
    TokenProvider? tokenProvider,
    UnauthorizedHandler? unauthorizedHandler,
    ErrorHandler? errorHandler,
    ResponseParser? responseParser,
    RetryPolicy? retryPolicy,
    TransformationHooks? transformationHooks,
    DeduplicationConfig? deduplicationConfig,
    CacheConfig? cacheConfig,
    bool enableLogging = false,
    String? locale,
  }) {
    // Use provided config or create default
    final NetworkConfig config =
        networkConfig ?? NetworkConfig(baseUrl: baseUrl);

    // Create Dio with performance optimizations
    final Dio dio = Dio(
      BaseOptions(
        baseUrl: config.baseUrl,
        connectTimeout: config.connectTimeout,
        receiveTimeout: config.receiveTimeout,
        sendTimeout: config.sendTimeout,
        headers: config.defaultHeaders,
        // Performance: Enable HTTP/2 if supported
        followRedirects: true,
        maxRedirects: 5,
        // Performance: Connection pooling (handled by Dio internally)
        // Dio automatically manages connection pooling
      ),
    );

    // Interceptor execution order in Dio:
    // - Request: interceptors are called in LIST ORDER (first added → last added)
    // - Response/Error: interceptors are called in REVERSE ORDER (last added → first added)
    //
    // Order rationale:
    // 0. Deduplication: First to prevent duplicate requests from even starting
    // 1. Cache: Check cache before making network request
    // 2. Retry: Handle errors, allows retry after auth refresh
    // 3. Transformation: Transform request data before auth headers are added
    // 4. Auth: Add auth headers (QueuedInterceptor handles 401 retry internally)
    // 5. Logger: Last in list = logs final request, logs raw response first
    final List<Interceptor> interceptors = <Interceptor>[];

    // 0. Deduplication interceptor (optional)
    // Request order: 1st (prevents duplicate requests from even starting)
    if (deduplicationConfig != null) {
      interceptors.add(DeduplicationInterceptor(config: deduplicationConfig));
    }

    // 1. Cache interceptor (optional)
    // Request order: 2nd (returns cached response if available)
    // Response order: Caches successful responses
    if (cacheConfig != null) {
      interceptors.add(CacheInterceptor(config: cacheConfig));
    }

    // 2. Retry interceptor
    // Request order: 3rd | Error order: Last (can retry after all other error handlers)
    if (retryPolicy != null && retryPolicy != RetryPolicy.noRetry) {
      interceptors.add(RetryInterceptor(dio: dio, policy: retryPolicy));
    }

    // 2. Transformation interceptor
    // Request order: 2nd (transforms data before auth) | Response order: 2nd-to-last
    if (transformationHooks != null) {
      interceptors.add(TransformationInterceptor(hooks: transformationHooks));
    }

    // 3. Auth interceptor (with token refresh capability)
    // Request order: 3rd (adds auth headers) | Error order: handles 401 internally
    interceptors.add(
      AuthInterceptor(
        dio: dio,
        tokenProvider: tokenProvider ?? const NoAuthTokenProvider(),
        unauthorizedHandler:
            unauthorizedHandler ?? const NoOpUnauthorizedHandler(),
        locale: locale,
      ),
    );

    // 4. Logging interceptor (optional)
    // Request order: Last (logs final request) | Response order: First (logs raw response)
    if (enableLogging) {
      interceptors.add(DioLogger());
    }

    dio.interceptors.addAll(interceptors);

    // Create and return client
    return RemoteClientImpl(
      dio: dio,
      errorHandler: errorHandler ?? ErrorHandlerImpl(),
      responseParser: responseParser ?? const DefaultResponseParser(),
    );
  }

  /// Create a RemoteClient with builder pattern for fluent configuration
  factory RemoteClientFactory.builder() => RemoteClientFactory._();

  RemoteClientFactory._();

  String? _baseUrl;
  NetworkConfig? _networkConfig;
  TokenProvider? _tokenProvider;
  UnauthorizedHandler? _unauthorizedHandler;
  ErrorHandler? _errorHandler;
  ResponseParser? _responseParser;
  RetryPolicy? _retryPolicy;
  TransformationHooks? _transformationHooks;
  DeduplicationConfig? _deduplicationConfig;
  CacheConfig? _cacheConfig;
  bool _enableLogging = false;
  String? _locale;

  /// Set base URL
  RemoteClientFactory baseUrl(String url) {
    _baseUrl = url;
    return this;
  }

  /// Set network configuration
  RemoteClientFactory withNetworkConfig(NetworkConfig config) {
    _networkConfig = config;
    return this;
  }

  /// Set authentication
  RemoteClientFactory withAuth({
    TokenProvider? tokenProvider,
    UnauthorizedHandler? unauthorizedHandler,
    String? locale,
  }) {
    _tokenProvider = tokenProvider;
    _unauthorizedHandler = unauthorizedHandler;
    _locale = locale;
    return this;
  }

  /// Set error handler
  RemoteClientFactory withErrorHandler(ErrorHandler handler) {
    _errorHandler = handler;
    return this;
  }

  /// Set response parser
  RemoteClientFactory withResponseParser(ResponseParser parser) {
    _responseParser = parser;
    return this;
  }

  /// Set retry policy
  RemoteClientFactory withRetry(RetryPolicy policy) {
    _retryPolicy = policy;
    return this;
  }

  /// Set transformation hooks for request/response transformation
  RemoteClientFactory withTransformationHooks(TransformationHooks hooks) {
    _transformationHooks = hooks;
    return this;
  }

  /// Set deduplication config to prevent duplicate concurrent requests
  RemoteClientFactory withDeduplication(DeduplicationConfig config) {
    _deduplicationConfig = config;
    return this;
  }

  /// Set cache config for HTTP response caching
  RemoteClientFactory withCache(CacheConfig config) {
    _cacheConfig = config;
    return this;
  }

  /// Enable logging
  RemoteClientFactory enableLogging({bool enabled = true}) {
    _enableLogging = enabled;
    return this;
  }

  /// Build the RemoteClient
  RemoteClientImpl build() {
    if (_baseUrl == null && _networkConfig?.baseUrl == null) {
      throw ArgumentError(
        'baseUrl is required. Use baseUrl() or withNetworkConfig()',
      );
    }

    final String effectiveBaseUrl = _baseUrl ?? _networkConfig!.baseUrl;

    return RemoteClientFactory.create(
      baseUrl: effectiveBaseUrl,
      networkConfig: _networkConfig,
      tokenProvider: _tokenProvider,
      unauthorizedHandler: _unauthorizedHandler,
      errorHandler: _errorHandler,
      responseParser: _responseParser,
      retryPolicy: _retryPolicy,
      transformationHooks: _transformationHooks,
      deduplicationConfig: _deduplicationConfig,
      cacheConfig: _cacheConfig,
      enableLogging: _enableLogging,
      locale: _locale,
    );
  }
}
