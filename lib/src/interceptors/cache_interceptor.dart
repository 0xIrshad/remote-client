import 'package:dio/dio.dart';

/// Configuration for cache behavior
class CacheConfig {
  /// Default TTL for cached responses
  final Duration defaultTTL;

  /// Maximum number of cached entries (LRU eviction)
  final int maxEntries;

  /// Whether to cache only GET requests (recommended)
  final bool cacheGetOnly;

  /// Custom TTL per endpoint pattern (regex pattern -> TTL)
  final Map<String, Duration> endpointTTLs;

  const CacheConfig({
    this.defaultTTL = const Duration(minutes: 5),
    this.maxEntries = 100,
    this.cacheGetOnly = true,
    this.endpointTTLs = const <String, Duration>{},
  });

  /// Create config for aggressive caching (long TTL)
  factory CacheConfig.aggressive() => const CacheConfig(
    defaultTTL: Duration(hours: 1),
    maxEntries: 200,
  );

  /// Create config for minimal caching (short TTL)
  factory CacheConfig.minimal() => const CacheConfig(
    defaultTTL: Duration(seconds: 30),
    maxEntries: 50,
  );
}

/// Cache entry with response data and expiration
class _CacheEntry {
  final Response<dynamic> response;
  final DateTime expiresAt;
  DateTime lastAccessed;

  _CacheEntry({
    required this.response,
    required this.expiresAt,
  }) : lastAccessed = DateTime.now();

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  void touch() {
    lastAccessed = DateTime.now();
  }
}

/// HTTP response cache interceptor with LRU eviction
///
/// Features:
/// - Configurable TTL per endpoint
/// - LRU eviction when cache is full
/// - GET-only caching by default
/// - Cache key based on URL + query params
/// - Manual cache invalidation support
class CacheInterceptor extends Interceptor {
  final CacheConfig config;

  /// In-memory cache storage
  /// Key: cache key (URL + sorted query params)
  /// Value: cache entry with response and expiration
  final Map<String, _CacheEntry> _cache = <String, _CacheEntry>{};

  CacheInterceptor({this.config = const CacheConfig()});

  /// Generate cache key from request options
  String _generateCacheKey(RequestOptions options) {
    final StringBuffer key = StringBuffer(options.uri.toString());

    // Include request data in key for POST/PUT if caching non-GET
    if (!config.cacheGetOnly && options.data != null) {
      key.write('|${options.data.hashCode}');
    }

    return key.toString();
  }

  /// Get TTL for a specific endpoint
  Duration _getTTL(String path) {
    // Check custom endpoint TTLs
    for (final MapEntry<String, Duration> entry in config.endpointTTLs.entries) {
      if (RegExp(entry.key).hasMatch(path)) {
        return entry.value;
      }
    }
    return config.defaultTTL;
  }

  /// Evict least recently used entries when cache is full
  void _evictLRU() {
    if (_cache.length < config.maxEntries) return;

    // Sort by last accessed time and remove oldest
    final List<MapEntry<String, _CacheEntry>> entries = _cache.entries.toList()
      ..sort(
        (MapEntry<String, _CacheEntry> a, MapEntry<String, _CacheEntry> b) =>
            a.value.lastAccessed.compareTo(b.value.lastAccessed),
      );

    // Remove oldest 10% of entries
    final int toRemove = (config.maxEntries * 0.1).ceil().clamp(1, entries.length);
    for (int i = 0; i < toRemove; i++) {
      _cache.remove(entries[i].key);
    }
  }

  /// Remove expired entries
  void _evictExpired() {
    _cache.removeWhere((String key, _CacheEntry entry) => entry.isExpired);
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Skip caching for non-GET if configured
    if (config.cacheGetOnly && options.method.toUpperCase() != 'GET') {
      handler.next(options);
      return;
    }

    // Check for cache bypass header
    if (options.extra['skipCache'] == true) {
      handler.next(options);
      return;
    }

    final String cacheKey = _generateCacheKey(options);
    final _CacheEntry? entry = _cache[cacheKey];

    if (entry != null && !entry.isExpired) {
      // Cache hit - return cached response
      entry.touch();
      handler.resolve(entry.response);
      return;
    }

    // Cache miss or expired - proceed with request
    if (entry != null && entry.isExpired) {
      _cache.remove(cacheKey);
    }

    // Store cache key for response handler
    options.extra['_cacheKey'] = cacheKey;
    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final String? cacheKey = response.requestOptions.extra['_cacheKey'] as String?;

    // Only cache successful responses
    if (cacheKey != null &&
        response.statusCode != null &&
        response.statusCode! >= 200 &&
        response.statusCode! < 300) {
      // Evict expired and LRU entries before adding
      _evictExpired();
      _evictLRU();

      // Calculate expiration
      final Duration ttl = _getTTL(response.requestOptions.path);
      final DateTime expiresAt = DateTime.now().add(ttl);

      // Cache the response
      _cache[cacheKey] = _CacheEntry(
        response: response,
        expiresAt: expiresAt,
      );
    }

    handler.next(response);
  }

  /// Clear all cached entries
  void clearAll() {
    _cache.clear();
  }

  /// Clear cached entries matching a pattern
  void clearMatching(String pattern) {
    final RegExp regex = RegExp(pattern);
    _cache.removeWhere((String key, _CacheEntry entry) => regex.hasMatch(key));
  }

  /// Clear a specific cache entry
  void clear(String url) {
    _cache.remove(url);
  }

  /// Get current cache size
  int get size => _cache.length;

  /// Check if a URL is cached
  bool isCached(String url) {
    final _CacheEntry? entry = _cache[url];
    return entry != null && !entry.isExpired;
  }
}
