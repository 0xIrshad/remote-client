/// Configuration for retry mechanism
/// Follows enterprise best practices for HTTP retry logic
class RetryPolicy {
  /// Maximum number of retry attempts
  final int maxRetries;

  /// Initial delay before first retry (in milliseconds)
  final int initialDelayMs;

  /// Maximum delay between retries (in milliseconds)
  final int maxDelayMs;

  /// Exponential backoff multiplier
  final double backoffMultiplier;

  /// Whether to use jitter (randomization) to prevent thundering herd
  final bool useJitter;

  /// HTTP status codes that should trigger a retry
  final Set<int> retryableStatusCodes;

  /// Whether to retry on connection errors
  final bool retryOnConnectionError;

  /// Whether to retry on timeout errors
  final bool retryOnTimeout;

  /// Whether to retry on 5xx server errors
  final bool retryOnServerError;

  /// Custom function to determine if an error should be retried
  /// Returns true if the request should be retried
  final bool Function(dynamic error)? shouldRetry;

  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelayMs = 1000,
    this.maxDelayMs = 10000,
    this.backoffMultiplier = 2.0,
    this.useJitter = true,
    this.retryableStatusCodes = const <int>{500, 502, 503, 504},
    this.retryOnConnectionError = true,
    this.retryOnTimeout = true,
    this.retryOnServerError = true,
    this.shouldRetry,
  });

  /// Default retry policy with enterprise best practices
  /// - 3 retries max
  /// - Exponential backoff with jitter
  /// - Retries on network errors, timeouts, and 5xx errors
  /// - Does not retry on 4xx client errors
  static const RetryPolicy defaultPolicy = RetryPolicy();

  /// No retry policy - disables retry mechanism
  static const RetryPolicy noRetry = RetryPolicy(
    maxRetries: 0,
    retryOnConnectionError: false,
    retryOnTimeout: false,
    retryOnServerError: false,
  );

  /// Aggressive retry policy for high-reliability scenarios
  /// - 5 retries max
  /// - Longer delays
  static const RetryPolicy aggressive = RetryPolicy(
    maxRetries: 5,
    initialDelayMs: 500,
    maxDelayMs: 30000,
    retryableStatusCodes: <int>{500, 502, 503, 504, 429},
  );

  /// Conservative retry policy for cost-sensitive scenarios
  /// - 1 retry only
  /// - Shorter delays
  static const RetryPolicy conservative = RetryPolicy(
    maxRetries: 1,
    initialDelayMs: 2000,
    maxDelayMs: 5000,
    backoffMultiplier: 1.5,
    retryableStatusCodes: <int>{503, 504},
    retryOnTimeout: false,
    retryOnServerError: false,
  );
}
