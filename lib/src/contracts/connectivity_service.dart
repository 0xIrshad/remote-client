/// Connectivity service abstraction
/// Allows different connectivity checking implementations
abstract class ConnectivityService {
  /// Check if device has internet connectivity
  Future<bool> isConnected();
}
