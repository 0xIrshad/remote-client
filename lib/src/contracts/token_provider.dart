/// Token provider abstraction for HTTP interceptors
/// This provides a clean way to inject token functionality without
/// coupling core infrastructure to specific authentication features
abstract class TokenProvider {
  /// Get the current access token for API requests
  /// Returns null if no token is available
  String? getAccessToken();

  /// Check if the current token is valid and not expired
  bool get hasValidToken;
}

/// No-op implementation for when authentication is not needed
class NoAuthTokenProvider implements TokenProvider {
  const NoAuthTokenProvider();

  @override
  String? getAccessToken() => null;

  @override
  bool get hasValidToken => false;
}
