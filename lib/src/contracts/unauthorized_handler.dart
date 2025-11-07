/// Handler for unauthorized (401) responses
/// This provides a clean way to handle auth failures without
/// coupling core infrastructure to specific authentication features
abstract class UnauthorizedHandler {
  /// Handle unauthorized response (e.g., redirect to login, refresh token)
  Future<void> handleUnauthorized();
}

/// No-op implementation for when authentication handling is not needed
class NoOpUnauthorizedHandler implements UnauthorizedHandler {
  const NoOpUnauthorizedHandler();

  @override
  Future<void> handleUnauthorized() async {
    // Do nothing - can be used in apps without authentication
  }
}
