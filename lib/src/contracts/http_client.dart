import 'package:dio/dio.dart';

import 'package:remote_client/src/models/base_response.dart';
import 'package:remote_client/src/models/request_timeout_config.dart';
import 'package:remote_client/src/types/either.dart';
import 'package:remote_client/src/types/failure.dart';

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
