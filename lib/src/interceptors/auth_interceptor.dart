import 'package:dio/dio.dart';
import '../contracts/token_provider.dart';
import '../contracts/unauthorized_handler.dart';

/// HTTP interceptor that adds authentication headers and handles unauthorized responses
/// Uses abstractions to avoid coupling with specific authentication implementations
/// Performance-optimized: Minimal overhead, only adds headers when needed
class AuthInterceptor extends Interceptor {
  final TokenProvider _tokenProvider;
  final UnauthorizedHandler _unauthorizedHandler;
  final String? _locale;

  /// Creates an [AuthInterceptor] that injects tokens and handles unauthorized responses.
  ///
  /// [tokenProvider] supplies access tokens for outbound requests, while
  /// [unauthorizedHandler] is invoked whenever a 401 response is encountered.
  /// Optionally provide [locale] to include a locale header on each request.
  AuthInterceptor({
    required TokenProvider tokenProvider,
    required UnauthorizedHandler unauthorizedHandler,
    String? locale,
  }) : _tokenProvider = tokenProvider,
       _unauthorizedHandler = unauthorizedHandler,
       _locale = locale;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Add authorization header if token is available
    // Performance: Only check token once, avoid unnecessary checks
    final token = _tokenProvider.getAccessToken();
    if (token != null && _tokenProvider.hasValidToken) {
      options.headers['Authorization'] = 'Bearer $token';
    }

    // Add locale header if provided
    if (_locale != null) {
      options.headers['locale'] = _locale;
    }

    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) async {
    // Handle unauthorized responses
    if (err.response?.statusCode == 401) {
      await _unauthorizedHandler.handleUnauthorized();
    }

    handler.next(err);
  }
}
