import 'package:dio/dio.dart';

import 'package:remote_client/src/models/base_response.dart';
import 'package:remote_client/src/types/either.dart';
import 'package:remote_client/src/types/failure.dart';

/// Error handler abstraction for processing Dio exceptions and validating responses
abstract class ErrorHandler {
  /// Handle DioException and convert to Failure
  Failure handleDioException(DioException exception);

  /// Validate response and convert to Either
  Either<Failure, BaseResponse<T>> validateResponse<T>(
    BaseResponse<T> response,
  );
}
