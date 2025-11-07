import 'package:dio/dio.dart';

/// Network failure types for error handling
/// Simple sealed class for type-safe error handling
sealed class Failure {
  final String? message;
  final Response<dynamic>? response;

  const Failure({this.message, this.response});

  String get errorMessage => message ?? 'An error occurred';
}

/// Thrown when a request times out during connection establishment.
class ConnectionTimeout extends Failure {
  const ConnectionTimeout({super.message, super.response});
}

/// Thrown when sending the request body exceeds the configured timeout.
class SendTimeout extends Failure {
  const SendTimeout({super.message, super.response});
}

/// Thrown when receiving the response exceeds the configured timeout.
class ReceiveTimeout extends Failure {
  const ReceiveTimeout({super.message, super.response});
}

/// Indicates a failure to reach the server due to connectivity issues.
class ConnectionError extends Failure {
  const ConnectionError({super.message, super.response});
}

/// Represents an unexpected or malformed server response.
class BadResponse extends Failure {
  const BadResponse({super.message, super.response});
}

/// Thrown when TLS/SSL certificate validation fails.
class BadCertificate extends Failure {
  const BadCertificate({super.message, super.response});
}

/// Indicates that the request was not authorized (HTTP 401/403).
class Unauthorized extends Failure {
  const Unauthorized({super.message, super.response});
}

/// Represents a client-side error caused by invalid input (HTTP 400/422).
class BadRequest extends Failure {
  const BadRequest({super.message, super.response});
}

/// Represents a server-side error (HTTP 500).
class InternalServerError extends Failure {
  const InternalServerError({super.message, super.response});
}

/// Indicates that the service is temporarily unavailable (HTTP 503).
class ServiceUnavailable extends Failure {
  const ServiceUnavailable({super.message, super.response});
}

/// Indicates that the requested resource could not be found (HTTP 404).
class NotFound extends Failure {
  const NotFound({super.message, super.response});
}

/// Thrown when no internet connection is available.
class NoInternet extends Failure {
  const NoInternet({super.message, super.response});
}

/// Indicates that the request was cancelled intentionally.
class Cancelled extends Failure {
  const Cancelled({super.message, super.response});
}

/// Represents an unexpected error that does not match other types.
class Unexpected extends Failure {
  const Unexpected({super.message, super.response});
}
