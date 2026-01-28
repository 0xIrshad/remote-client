import 'dart:async';

import 'package:dio/dio.dart';

/// Configuration for request deduplication
class DeduplicationConfig {
  /// Time window for considering requests as duplicates
  /// Requests within this window are considered duplicates
  final Duration deduplicationWindow;

  /// Whether to deduplicate only GET requests (safest, recommended)
  final bool deduplicateGetOnly;

  /// Custom key generator for grouping requests
  /// Default uses method + path + sorted query params
  final String Function(RequestOptions)? keyGenerator;

  const DeduplicationConfig({
    this.deduplicationWindow = const Duration(milliseconds: 500),
    this.deduplicateGetOnly = true,
    this.keyGenerator,
  });

  /// Aggressive deduplication (longer window, all safe methods)
  factory DeduplicationConfig.aggressive() => const DeduplicationConfig(
    deduplicationWindow: Duration(seconds: 1),
    deduplicateGetOnly: false,
  );

  /// Conservative deduplication (short window, GET only)
  factory DeduplicationConfig.conservative() => const DeduplicationConfig(
    deduplicationWindow: Duration(milliseconds: 200),
  );
}

/// Pending request entry with completer for response
class _PendingRequest {
  final Completer<Response<dynamic>> completer;
  final DateTime createdAt;
  final List<RequestInterceptorHandler> waitingHandlers;

  _PendingRequest({
    required this.completer,
    required this.createdAt,
  }) : waitingHandlers = <RequestInterceptorHandler>[];

  bool isExpired(Duration window) {
    return DateTime.now().difference(createdAt) > window;
  }
}

/// Interceptor that deduplicates concurrent identical requests
///
/// Features:
/// - Prevents duplicate API calls for identical requests within a time window
/// - Configurable deduplication window
/// - Option to deduplicate only GET requests (safe) or all methods
/// - Custom key generator for advanced use cases
///
/// Use cases:
/// - Rapid button clicks triggering multiple API calls
/// - Multiple widgets requesting the same data simultaneously
/// - Scroll-triggered refreshes that fire multiple times
class DeduplicationInterceptor extends Interceptor {
  final DeduplicationConfig config;

  /// Map of pending requests: key -> pending request info
  final Map<String, _PendingRequest> _pendingRequests = <String, _PendingRequest>{};

  DeduplicationInterceptor({this.config = const DeduplicationConfig()});

  /// Generate a unique key for request deduplication
  String _generateKey(RequestOptions options) {
    if (config.keyGenerator != null) {
      return config.keyGenerator!(options);
    }

    // Default key: method + path + sorted query params
    final StringBuffer key = StringBuffer('${options.method}:${options.path}');

    if (options.queryParameters.isNotEmpty) {
      final List<String> sortedParams =
          options.queryParameters.entries
              .map((MapEntry<String, dynamic> e) => '${e.key}=${e.value}')
              .toList()
            ..sort();
      key.write('?${sortedParams.join('&')}');
    }

    // Include request data hash for POST/PUT/PATCH
    if (!config.deduplicateGetOnly && options.data != null) {
      key.write('|${options.data.hashCode}');
    }

    return key.toString();
  }

  /// Check if the request method should be deduplicated
  bool _shouldDeduplicate(RequestOptions options) {
    if (config.deduplicateGetOnly) {
      return options.method.toUpperCase() == 'GET';
    }
    // Deduplicate idempotent methods only (no POST by default for safety)
    const List<String> safeToDedup = <String>['GET', 'HEAD', 'OPTIONS'];
    return safeToDedup.contains(options.method.toUpperCase());
  }

  /// Cleanup expired pending requests
  void _cleanupExpired() {
    _pendingRequests.removeWhere(
      (String key, _PendingRequest request) => request.isExpired(config.deduplicationWindow),
    );
  }

  @override
  Future<void> onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    // Check if request can be skipped via extra flag
    if (options.extra['skipDeduplication'] == true) {
      handler.next(options);
      return;
    }

    // Only deduplicate appropriate methods
    if (!_shouldDeduplicate(options)) {
      handler.next(options);
      return;
    }

    // Cleanup expired entries
    _cleanupExpired();

    final String key = _generateKey(options);

    // Check if there's a pending request for this key
    final _PendingRequest? pending = _pendingRequests[key];
    if (pending != null && !pending.isExpired(config.deduplicationWindow)) {
      // Duplicate request - wait for the original to complete
      pending.waitingHandlers.add(handler);

      // When original completes, resolve this handler with the same response
      await pending.completer.future
          .then((Response<dynamic> response) {
            // Clone response for each waiting handler
            handler.resolve(
              Response<dynamic>(
                data: response.data,
                headers: response.headers,
                isRedirect: response.isRedirect,
                statusCode: response.statusCode,
                statusMessage: response.statusMessage,
                redirects: response.redirects,
                extra: response.extra,
                requestOptions: options, // Use original request options
              ),
            );
          })
          .catchError((Object error) {
            if (error is DioException) {
              handler.reject(error);
            } else {
              handler.reject(
                DioException(
                  requestOptions: options,
                  error: error,
                  message: 'Deduplication error: $error',
                ),
              );
            }
          });

      return;
    }

    // First request - create pending entry
    final Completer<Response<dynamic>> completer = Completer<Response<dynamic>>();
    _pendingRequests[key] = _PendingRequest(
      completer: completer,
      createdAt: DateTime.now(),
    );

    // Store key in extra for response/error handler
    options.extra['_deduplicationKey'] = key;

    handler.next(options);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    final String? key = response.requestOptions.extra['_deduplicationKey'] as String?;

    if (key != null && _pendingRequests.containsKey(key)) {
      final _PendingRequest? pending = _pendingRequests.remove(key);
      if (pending != null && !pending.completer.isCompleted) {
        pending.completer.complete(response);
      }
    }

    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final String? key = err.requestOptions.extra['_deduplicationKey'] as String?;

    if (key != null && _pendingRequests.containsKey(key)) {
      final _PendingRequest? pending = _pendingRequests.remove(key);
      if (pending != null && !pending.completer.isCompleted) {
        pending.completer.completeError(err);
      }
    }

    handler.next(err);
  }

  /// Clear all pending requests (useful for testing or cleanup)
  void clearAll() {
    _pendingRequests.clear();
  }

  /// Get current number of pending requests (for monitoring)
  int get pendingCount => _pendingRequests.length;
}
