import 'package:dio/dio.dart';
import '../models/base_response.dart';
import '../models/request_timeout_config.dart';
import '../types/either.dart';
import '../types/failure.dart';

/// Basic HTTP operations interface following ISP
/// Clients only depend on the operations they actually use
abstract class HttpClient {
  Future<Either<Failure, BaseResponse<T>>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<T>>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<T>>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<T>>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<void>>> delete(
    String endpoint, {
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });
}
