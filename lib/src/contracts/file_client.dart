import 'package:dio/dio.dart';
import '../models/base_response.dart';
import '../models/request_timeout_config.dart';
import '../types/either.dart';
import '../types/failure.dart';

/// File operations interface following ISP
/// Separated from basic HTTP operations for clients that need file handling
abstract class FileClient {
  Future<Either<Failure, BaseResponse<T>>> multiPartPost<T>(
    String endpoint, {
    required FormData data,
    Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<T>>> multiPartPatch<T>(
    String endpoint, {
    required FormData data,
    Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<void>>> download(
    String url,
    String path, {
    Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });
}
