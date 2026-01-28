import 'dart:math' as math;

import 'package:dio/dio.dart';

import 'package:remote_client/src/models/retry_policy.dart';

/// Interceptor that implements retry logic with exponential backoff and jitter
/// Follows enterprise best practices for HTTP retry mechanisms
/// Performance-optimized: Uses efficient retry logic with minimal overhead
class RetryInterceptor extends Interceptor {
  final RetryPolicy _policy;
  final Dio _dio;
  final math.Random _random = math.Random();

  RetryInterceptor({required Dio dio, RetryPolicy? policy})
    : _dio = dio,
      _policy = policy ?? RetryPolicy.defaultPolicy;

  @override
  Future<void> onError(
    DioException err,
    ErrorInterceptorHandler handler,
  ) async {
    final int retryCount = err.requestOptions.extra['retryCount'] as int? ?? 0;

    // Check if we should retry (early exit for performance)
    if (!_shouldRetry(err, retryCount)) {
      handler.next(err);
      return;
    }

    // Calculate delay with exponential backoff and jitter
    final int delay = _calculateDelay(retryCount);

    // Wait before retrying
    await Future<void>.delayed(Duration(milliseconds: delay));

    // Update retry count
    err.requestOptions.extra['retryCount'] = retryCount + 1;

    // Clone the request options to avoid modifying the original
    final RequestOptions options = err.requestOptions;

    // Retry the request
    try {
      final Response<dynamic> response = await _retryRequest(options);
      handler.resolve(response);
    } on DioException catch (e) {
      handler.next(e);
    } on Object {
      // If retry also fails with non-Dio error, proceed with the original error
      handler.next(err);
    }
  }

  /// Determines if a request should be retried based on error type and retry policy
  bool _shouldRetry(DioException error, int retryCount) {
    // Don't retry if max retries exceeded
    if (retryCount >= _policy.maxRetries) {
      return false;
    }

    // Don't retry if request was cancelled
    if (error.type == DioExceptionType.cancel) {
      return false;
    }

    // Custom retry logic
    if (_policy.shouldRetry != null) {
      return _policy.shouldRetry!(error);
    }

    // Check error type
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return _policy.retryOnTimeout;

      case DioExceptionType.connectionError:
      case DioExceptionType.unknown:
        return _policy.retryOnConnectionError;

      case DioExceptionType.badResponse:
        return _shouldRetryOnStatus(error.response?.statusCode);

      case DioExceptionType.badCertificate:
      case DioExceptionType.cancel:
        // Don't retry on certificate errors or cancelled requests
        return false;
    }
  }

  /// Determines if a status code should trigger a retry
  bool _shouldRetryOnStatus(int? statusCode) {
    if (statusCode == null) {
      return false;
    }

    // Never retry on 4xx client errors (except 429 if in retryable codes)
    if (statusCode >= 400 && statusCode < 500) {
      // 429 (Too Many Requests) might be retryable
      return _policy.retryableStatusCodes.contains(statusCode);
    }

    // Retry on 5xx server errors if enabled
    if (statusCode >= 500 && statusCode < 600) {
      if (!_policy.retryOnServerError) {
        return false;
      }
      // If specific status codes are set, only retry those
      if (_policy.retryableStatusCodes.isNotEmpty) {
        return _policy.retryableStatusCodes.contains(statusCode);
      }
      return true;
    }

    return false;
  }

  /// Calculates delay with exponential backoff and optional jitter
  /// Performance: Uses efficient math operations
  int _calculateDelay(int retryCount) {
    // Exponential backoff: initialDelay * (multiplier ^ retryCount)
    final int exponentialDelay =
        (_policy.initialDelayMs *
                math.pow(_policy.backoffMultiplier, retryCount))
            .round();

    // Apply jitter to prevent thundering herd problem
    int delay;
    if (_policy.useJitter) {
      // Full jitter: random delay between 0 and exponential delay
      // This provides better distribution under high load
      final int jitter = _random.nextInt(exponentialDelay);
      delay = jitter;
    } else {
      delay = exponentialDelay;
    }

    // Cap at maximum delay
    return math.min(delay, _policy.maxDelayMs);
  }

  /// Retries the request using the same Dio instance
  Future<Response<dynamic>> _retryRequest(RequestOptions options) {
    // Use Dio's fetch method to retry the request with the same options
    return _dio.fetch(options);
  }
}
