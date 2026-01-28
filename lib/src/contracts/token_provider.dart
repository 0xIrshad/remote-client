/// Token provider abstraction for HTTP interceptors
/// This provides a clean way to inject token functionality without
/// coupling core infrastructure to specific authentication features
abstract class TokenProvider {
  /// Get the current access token for API requests
  /// Returns null if no token is available
  /// Async to support token refresh and secure storage reads
  Future<String?> getAccessToken();

  /// Check if the current token is valid and not expired
  /// Async to support async validation if needed
  Future<bool> hasValidToken();

  /// Refresh the token if possible
  /// Returns the new token or null if refresh failed
  /// Used by AuthInterceptor to retry requests after 401
  Future<String?> refreshToken();
}

/// No-op implementation for when authentication is not needed
class NoAuthTokenProvider implements TokenProvider {
  const NoAuthTokenProvider();

  @override
  Future<String?> getAccessToken() async => null;

  @override
  Future<bool> hasValidToken() async => false;

  @override
  Future<String?> refreshToken() async => null;
}
