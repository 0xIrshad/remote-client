/// High-performance, standalone HTTP client package
///
/// Features:
/// - Only depends on Dio (no other external dependencies)
/// - Retry mechanism with exponential backoff
/// - Authentication interceptor
/// - Connectivity checking
/// - Error handling
/// - Configurable response parsing
/// - Performance-optimized
///
/// Example usage:
/// ```dart
/// final client = RemoteClientFactory.create(
///   baseUrl: 'https://api.example.com',
///   tokenProvider: myTokenProvider,
///   enableLogging: true,
/// );
///
/// final result = await client.get('/users');
/// result.fold(
///   (failure) => print('Error: ${failure.message}'),
///   (response) => print('Success: ${response.data}'),
/// );
/// ```
library;

// Core exports
export 'src/contracts/remote_client.dart';
export 'src/contracts/http_client.dart';
export 'src/contracts/file_client.dart';
export 'src/contracts/token_provider.dart';
export 'src/contracts/unauthorized_handler.dart';
export 'src/contracts/connectivity_service.dart';
export 'src/contracts/error_handler.dart';
export 'src/contracts/response_parser.dart';
export 'src/contracts/transformation_hooks.dart';

// Implementation exports
export 'src/remote_client_impl.dart';
export 'src/remote_client_factory.dart';

// Models
export 'src/models/base_response.dart';
export 'src/models/request_timeout_config.dart';
export 'src/models/retry_policy.dart';

// Types
export 'src/types/either.dart';
export 'src/types/failure.dart';

// Services
export 'src/services/connectivity_service_impl.dart';
export 'src/services/error_handler_impl.dart';
export 'src/services/response_parser_impl.dart';

// Interceptors
export 'src/interceptors/auth_interceptor.dart';
export 'src/interceptors/retry_interceptor.dart';
export 'src/interceptors/dio_logger.dart';
export 'src/interceptors/transformation_interceptor.dart';

// Config
export 'src/config/network_config.dart';
