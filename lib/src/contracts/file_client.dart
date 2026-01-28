import 'package:dio/dio.dart';

import 'package:remote_client/src/models/base_response.dart';
import 'package:remote_client/src/models/request_timeout_config.dart';
import 'package:remote_client/src/types/either.dart';
import 'package:remote_client/src/types/failure.dart';

/// File operations interface following ISP
/// Separated from basic HTTP operations for clients that need file handling
abstract class FileClient {
  Future<Either<Failure, BaseResponse<T>>> multiPartPost<T>(
    String endpoint, {
    required FormData data,
    void Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<T>>> multiPartPatch<T>(
    String endpoint, {
    required FormData data,
    void Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });

  Future<Either<Failure, BaseResponse<void>>> download(
    String url,
    String path, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  });
}
