import 'package:dio/dio.dart';
import 'config/network_config.dart';
import 'contracts/connectivity_service.dart';
import 'contracts/error_handler.dart';
import 'contracts/response_parser.dart';
import 'contracts/token_provider.dart';
import 'contracts/transformation_hooks.dart';
import 'contracts/unauthorized_handler.dart';
import 'interceptors/auth_interceptor.dart';
import 'interceptors/dio_logger.dart';
import 'interceptors/retry_interceptor.dart';
import 'interceptors/transformation_interceptor.dart';
import 'models/retry_policy.dart';
import 'remote_client_impl.dart';
import 'services/connectivity_service_impl.dart';
import 'services/error_handler_impl.dart';
import 'services/response_parser_impl.dart';

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
    ConnectivityService? connectivityService,
    ErrorHandler? errorHandler,
    ResponseParser? responseParser,
    RetryPolicy? retryPolicy,
    TransformationHooks? transformationHooks,
    bool enableLogging = false,
    String? locale,
  }) {
    // Use provided config or create default
    final config = networkConfig ?? NetworkConfig(baseUrl: baseUrl);

    // Create Dio with performance optimizations
    final dio = Dio(
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

    // Create interceptors in correct order for performance
    final interceptors = <Interceptor>[];

    // 1. Retry interceptor (should be first)
    if (retryPolicy != null && retryPolicy != RetryPolicy.noRetry) {
      interceptors.add(RetryInterceptor(dio: dio, policy: retryPolicy));
    }

    // 2. Transformation interceptor (before auth to transform request data)
    if (transformationHooks != null) {
      interceptors.add(TransformationInterceptor(hooks: transformationHooks));
    }

    // 3. Auth interceptor
    interceptors.add(
      AuthInterceptor(
        tokenProvider: tokenProvider ?? const NoAuthTokenProvider(),
        unauthorizedHandler:
            unauthorizedHandler ?? const NoOpUnauthorizedHandler(),
        locale: locale,
      ),
    );

    // 4. Logging interceptor (optional, last for minimal overhead)
    if (enableLogging) {
      interceptors.add(DioLogger());
    }

    dio.interceptors.addAll(interceptors);

    // Create and return client
    return RemoteClientImpl(
      dio: dio,
      connectivityService: connectivityService ?? ConnectivityServiceImpl(),
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
  ConnectivityService? _connectivityService;
  ErrorHandler? _errorHandler;
  ResponseParser? _responseParser;
  RetryPolicy? _retryPolicy;
  TransformationHooks? _transformationHooks;
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

  /// Set connectivity service
  RemoteClientFactory withConnectivityService(ConnectivityService service) {
    _connectivityService = service;
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

    final baseUrl = _baseUrl ?? _networkConfig!.baseUrl;

    return RemoteClientFactory.create(
      baseUrl: baseUrl,
      networkConfig: _networkConfig,
      tokenProvider: _tokenProvider,
      unauthorizedHandler: _unauthorizedHandler,
      connectivityService: _connectivityService,
      errorHandler: _errorHandler,
      responseParser: _responseParser,
      retryPolicy: _retryPolicy,
      transformationHooks: _transformationHooks,
      enableLogging: _enableLogging,
      locale: _locale,
    );
  }
}
