import '../contracts/connectivity_service.dart';

/// Fallback connectivity service used on platforms where `dart:io` is
/// unavailable (web/WASM).
///
/// The implementation keeps the same API surface as the IO version but avoids
/// performing any socket-based DNS lookups. Instead, it assumes connectivity is
/// available and provides caching behaviour so the rest of the package can
/// function without runtime errors.
class ConnectivityServiceImpl implements ConnectivityService {
  final List<String> checkHosts;
  final Duration timeout;
  final Duration cacheTTL;

  bool? _cachedResult;
  DateTime? _cacheTimestamp;

  static const List<String> defaultHosts = [
    'google.com',
    'cloudflare.com',
    'example.com',
  ];

  static const Duration defaultCacheTTL = Duration(seconds: 5);

  ConnectivityServiceImpl({
    List<String>? checkHosts,
    this.timeout = const Duration(seconds: 3),
    Duration? cacheTTL,
  }) : checkHosts = checkHosts ?? defaultHosts,
       cacheTTL = cacheTTL ?? defaultCacheTTL;

  factory ConnectivityServiceImpl.withHost(
    String host, {
    Duration timeout = const Duration(seconds: 3),
    Duration? cacheTTL,
  }) {
    return ConnectivityServiceImpl(
      checkHosts: [host],
      timeout: timeout,
      cacheTTL: cacheTTL,
    );
  }

  factory ConnectivityServiceImpl.withHosts(
    List<String> hosts, {
    Duration timeout = const Duration(seconds: 3),
    Duration? cacheTTL,
  }) {
    return ConnectivityServiceImpl(
      checkHosts: hosts,
      timeout: timeout,
      cacheTTL: cacheTTL,
    );
  }

  factory ConnectivityServiceImpl.noCache({
    List<String>? checkHosts,
    Duration timeout = const Duration(seconds: 3),
  }) {
    return ConnectivityServiceImpl(
      checkHosts: checkHosts,
      timeout: timeout,
      cacheTTL: Duration.zero,
    );
  }

  @override
  Future<bool> isConnected() async {
    if (_cachedResult != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < cacheTTL) {
      return _cachedResult!;
    }

    final result = await _performConnectivityCheck();
    _cachedResult = result;
    _cacheTimestamp = DateTime.now();
    return result;
  }

  Future<bool> _performConnectivityCheck() async {
    // Without socket APIs we optimistically assume connectivity.
    // Consumers can provide their own connectivity service if stricter
    // behaviour is required.
    return true;
  }

  void clearCache() {
    _cachedResult = null;
    _cacheTimestamp = null;
  }
}
