import 'dart:async';
import 'dart:io';

import 'package:remote_client/src/contracts/connectivity_service.dart';

/// Default connectivity service implementation using DNS lookup.
///
/// This implementation is used on platforms where `dart:io` is available.
class ConnectivityServiceImpl implements ConnectivityService {
  /// DNS hosts to check connectivity (lightweight check)
  /// Checks hosts in order until one succeeds
  final List<String> checkHosts;

  /// Timeout for each connectivity check
  final Duration timeout;

  /// Cache TTL (Time To Live) for connectivity results
  /// Default: 5 seconds (balances freshness with performance)
  final Duration cacheTTL;

  /// Cached connectivity result
  bool? _cachedResult;

  /// Timestamp when the cache was last updated
  DateTime? _cacheTimestamp;

  /// Default reliable hosts for connectivity checking
  /// Uses multiple public DNS servers and popular services as fallbacks
  static const List<String> defaultHosts = <String>[
    '8.8.8.8', // Google DNS (most reliable)
    '1.1.1.1', // Cloudflare DNS (fast fallback)
    'google.com', // Google (common fallback)
    'cloudflare.com', // Cloudflare (alternative)
  ];

  /// Default cache TTL (5 seconds)
  static const Duration defaultCacheTTL = Duration(seconds: 5);

  ConnectivityServiceImpl({
    List<String>? checkHosts,
    this.timeout = const Duration(seconds: 3),
    Duration? cacheTTL,
  }) : checkHosts = checkHosts ?? defaultHosts,
       cacheTTL = cacheTTL ?? defaultCacheTTL;

  /// Create instance with custom single host (backward compatibility)
  factory ConnectivityServiceImpl.withHost(
    String host, {
    Duration timeout = const Duration(seconds: 3),
    Duration? cacheTTL,
  }) {
    return ConnectivityServiceImpl(
      checkHosts: <String>[host],
      timeout: timeout,
      cacheTTL: cacheTTL,
    );
  }

  /// Create instance with custom hosts list
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

  /// Create instance with disabled caching (always checks connectivity)
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
    // Check if cached result is still valid
    if (_cachedResult != null &&
        _cacheTimestamp != null &&
        DateTime.now().difference(_cacheTimestamp!) < cacheTTL) {
      return _cachedResult!;
    }

    // Cache expired or not set, perform actual check
    final bool result = await _performConnectivityCheck();

    // Update cache
    _cachedResult = result;
    _cacheTimestamp = DateTime.now();

    return result;
  }

  /// Perform the actual connectivity check
  /// Uses parallel lookup for all hosts - returns true on first success
  /// This is much faster than sequential checking (worst case: timeout vs N*timeout)
  ///
  /// Performance optimization: Returns immediately when ANY host succeeds,
  /// rather than waiting for all hosts to complete (which would wait for slowest/timeout).
  Future<bool> _performConnectivityCheck() async {
    if (checkHosts.isEmpty) {
      return false;
    }

    // Use Completer for early return on first success
    final Completer<bool> completer = Completer<bool>();
    int failureCount = 0;
    final int totalHosts = checkHosts.length;

    for (final String host in checkHosts) {
      await _lookupHost(host).then((bool success) {
        if (completer.isCompleted) return;

        if (success) {
          // First success - return immediately
          completer.complete(true);
        } else {
          failureCount++;
          // All hosts failed - return false
          if (failureCount == totalHosts) {
            completer.complete(false);
          }
        }
      });
    }

    return completer.future;
  }

  /// Lookup a single host and return success/failure
  Future<bool> _lookupHost(String host) async {
    try {
      final List<InternetAddress> result = await InternetAddress.lookup(host)
          .timeout(
            timeout,
            onTimeout: () => throw const SocketException('Timeout'),
          );
      return result.isNotEmpty && result[0].rawAddress.isNotEmpty;
    } on SocketException catch (_) {
      return false;
    } on Object catch (_) {
      return false;
    }
  }

  /// Clear the connectivity cache
  /// Useful when you want to force a fresh connectivity check
  void clearCache() {
    _cachedResult = null;
    _cacheTimestamp = null;
  }
}
