import 'package:dio/dio.dart';

import 'package:remote_client/src/contracts/error_handler.dart';
import 'package:remote_client/src/models/base_response.dart';
import 'package:remote_client/src/types/either.dart';
import 'package:remote_client/src/types/failure.dart';

/// Default error handler implementation
class ErrorHandlerImpl implements ErrorHandler {
  @override
  Failure handleDioException(DioException exception) {
    // Extract request ID for better error context
    final String? requestId =
        exception.requestOptions.extra['requestId'] as String?;
    final String requestIdContext = requestId != null
        ? ' [Request ID: $requestId]'
        : '';

    // Build enhanced error message with context
    String buildMessage(String baseMessage) {
      final String message = baseMessage + requestIdContext;
      if (exception.requestOptions.uri.toString().isNotEmpty) {
        return '$message [URI: ${exception.requestOptions.uri}]';
      }
      return message;
    }

    switch (exception.type) {
      case DioExceptionType.connectionTimeout:
        return ConnectionTimeout(
          message: buildMessage(exception.message ?? 'Connection timeout'),
          response: exception.response,
        );

      case DioExceptionType.sendTimeout:
        return SendTimeout(
          message: buildMessage(exception.message ?? 'Send timeout'),
          response: exception.response,
        );

      case DioExceptionType.receiveTimeout:
        return ReceiveTimeout(
          message: buildMessage(exception.message ?? 'Receive timeout'),
          response: exception.response,
        );

      case DioExceptionType.badResponse:
        return _handleBadResponse(exception.response, requestIdContext);

      case DioExceptionType.cancel:
        return Cancelled(message: 'Request cancelled$requestIdContext');

      case DioExceptionType.unknown:
        // Check for socket/network errors without importing dart:io
        final String errorType = exception.error?.runtimeType.toString() ?? '';
        if (errorType.contains('SocketException') ||
            errorType.contains('NetworkException')) {
          return NoInternet(
            message:
                'Network error, please check your internet connection$requestIdContext',
          );
        }
        return ConnectionError(
          message: buildMessage(exception.message ?? 'Connection error'),
          response: exception.response,
        );

      case DioExceptionType.badCertificate:
        return BadCertificate(
          message: buildMessage(exception.message ?? 'Bad certificate'),
          response: exception.response,
        );

      case DioExceptionType.connectionError:
        return ConnectionError(
          message: buildMessage(exception.message ?? 'Connection error'),
          response: exception.response,
        );
    }
  }

  @override
  Either<Failure, BaseResponse<T>> validateResponse<T>(
    BaseResponse<T> response,
  ) {
    switch (response.statusCode) {
      case 200:
      case 201:
      case 202:
      case 204:
        return Right<Failure, BaseResponse<T>>(response);
      case 400:
        return Left<Failure, BaseResponse<T>>(
          BadRequest(message: response.message),
        );
      case 401:
        return Left<Failure, BaseResponse<T>>(
          Unauthorized(message: response.message),
        );
      case 403:
        return Left<Failure, BaseResponse<T>>(
          Unauthorized(message: response.message),
        );
      case 404:
        return Left<Failure, BaseResponse<T>>(
          NotFound(message: response.message),
        );
      case 422:
        return Left<Failure, BaseResponse<T>>(
          BadRequest(message: response.message),
        );
      case 500:
        return Left<Failure, BaseResponse<T>>(
          InternalServerError(message: response.message),
        );
      case 503:
        return Left<Failure, BaseResponse<T>>(
          ServiceUnavailable(
            message:
                "Service temporarily unavailable. ${response.message ?? ''}",
          ),
        );
      default:
        return Left<Failure, BaseResponse<T>>(
          BadResponse(message: "Unknown error: ${response.message ?? ''}"),
        );
    }
  }

  Failure _handleBadResponse(
    Response<dynamic>? response,
    String requestIdContext,
  ) {
    String? message;

    // Try to extract message from response
    if (response?.data is Map<String, dynamic>) {
      final Map<String, dynamic> dataMap =
          response?.data as Map<String, dynamic>;
      message = dataMap['message'] as String?;
    }

    message ??= response?.statusMessage ?? 'Invalid server response';

    // Add request ID context to message
    final String enhancedMessage = message + requestIdContext;

    // Add status code context if available
    final String statusCodeContext = response?.statusCode != null
        ? ' [Status: ${response?.statusCode}]'
        : '';

    switch (response?.statusCode) {
      case 400:
        return BadRequest(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
      case 401:
      case 403:
        return Unauthorized(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
      case 404:
        return NotFound(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
      case 422:
        return BadRequest(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
      case 500:
        return InternalServerError(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
      case 503:
        return ServiceUnavailable(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
      default:
        return BadResponse(
          message: enhancedMessage + statusCodeContext,
          response: response,
        );
    }
  }
}
