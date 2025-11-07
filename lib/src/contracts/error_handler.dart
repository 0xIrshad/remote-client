import 'package:dio/dio.dart';
import '../models/base_response.dart';
import '../types/either.dart';
import '../types/failure.dart';

/// Error handler abstraction for processing Dio exceptions and validating responses
abstract class ErrorHandler {
  /// Handle DioException and convert to Failure
  Failure handleDioException(DioException exception);

  /// Validate response and convert to Either
  Either<Failure, BaseResponse<T>> validateResponse<T>(
    BaseResponse<T> response,
  );
}
