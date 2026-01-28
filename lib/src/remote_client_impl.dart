import 'dart:math';

import 'package:dio/dio.dart';

import 'package:remote_client/src/contracts/error_handler.dart';
import 'package:remote_client/src/contracts/remote_client.dart';
import 'package:remote_client/src/contracts/response_parser.dart';
import 'package:remote_client/src/models/base_response.dart';
import 'package:remote_client/src/models/request_timeout_config.dart';
import 'package:remote_client/src/services/response_parser_impl.dart';
import 'package:remote_client/src/types/either.dart';
import 'package:remote_client/src/types/failure.dart';

/// High-performance HTTP client implementation
/// Performance optimizations:
/// - Connection pooling via Dio
/// - Efficient error handling
/// - Minimal object allocation
/// - Optimized request execution
/// - Request ID tracking for debugging
class RemoteClientImpl implements RemoteClient {
  final Dio _dio;
  final ErrorHandler _errorHandler;
  final ResponseParser _responseParser;
  final bool _enableRequestId;

  /// Secure random generator for UUID generation
  /// Using secure random to prevent ID prediction and ensure uniqueness
  static final Random _secureRandom = Random.secure();

  RemoteClientImpl({
    required Dio dio,
    required ErrorHandler errorHandler,
    ResponseParser? responseParser,
    bool enableRequestId = true,
  }) : _dio = dio,
       _errorHandler = errorHandler,
       _responseParser = responseParser ?? const DefaultResponseParser(),
       _enableRequestId = enableRequestId;

  /// Generate a UUID v4 for request tracking
  /// Format: xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx (RFC 4122)
  /// Uses cryptographically secure random for uniqueness across instances
  String _generateRequestId() {
    if (!_enableRequestId) return '';

    // Generate 16 random bytes
    final List<int> bytes = List<int>.generate(
      16,
      (_) => _secureRandom.nextInt(256),
    );

    // Set version (4) and variant bits per RFC 4122
    bytes[6] = (bytes[6] & 0x0f) | 0x40; // Version 4
    bytes[8] = (bytes[8] & 0x3f) | 0x80; // Variant 1

    // Convert to hex string with dashes
    String hex(int byte) => byte.toRadixString(16).padLeft(2, '0');

    return '${hex(bytes[0])}${hex(bytes[1])}${hex(bytes[2])}${hex(bytes[3])}-'
        '${hex(bytes[4])}${hex(bytes[5])}-'
        '${hex(bytes[6])}${hex(bytes[7])}-'
        '${hex(bytes[8])}${hex(bytes[9])}-'
        '${hex(bytes[10])}${hex(bytes[11])}${hex(bytes[12])}${hex(bytes[13])}${hex(bytes[14])}${hex(bytes[15])}';
  }

  /// Merge options with request ID if enabled
  Options? _mergeOptionsWithRequestId(Options? options) {
    if (!_enableRequestId) return options;

    final String requestId = _generateRequestId();
    final Map<String, dynamic> extra = <String, dynamic>{
      ...?options?.extra,
      'requestId': requestId,
    };

    return Options(
      method: options?.method,
      sendTimeout: options?.sendTimeout,
      receiveTimeout: options?.receiveTimeout,
      extra: extra,
      headers: options?.headers,
      responseType: options?.responseType,
      validateStatus: options?.validateStatus,
      receiveDataWhenStatusError: options?.receiveDataWhenStatusError,
      followRedirects: options?.followRedirects,
      maxRedirects: options?.maxRedirects,
      requestEncoder: options?.requestEncoder,
      responseDecoder: options?.responseDecoder,
      listFormat: options?.listFormat,
      contentType: options?.contentType,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<T>>> get<T>(
    String endpoint, {
    Map<String, dynamic>? queryParams,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? mergedOptions = _mergeOptionsWithRequestId(baseOptions);
    return _executeRequest<T>(
      () => _dio.get(
        endpoint,
        queryParameters: queryParams,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      fromJson,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<T>>> post<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? mergedOptions = _mergeOptionsWithRequestId(baseOptions);
    return _executeRequest<T>(
      () => _dio.post(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      fromJson,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<T>>> put<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? mergedOptions = _mergeOptionsWithRequestId(baseOptions);
    return _executeRequest<T>(
      () => _dio.put(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      fromJson,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<T>>> patch<T>(
    String endpoint, {
    Map<String, dynamic>? data,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? mergedOptions = _mergeOptionsWithRequestId(baseOptions);
    return _executeRequest<T>(
      () => _dio.patch(
        endpoint,
        data: data,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      fromJson,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<void>>> delete(
    String endpoint, {
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? mergedOptions = _mergeOptionsWithRequestId(baseOptions);
    return _executeRequest<void>(
      () => _dio.delete(
        endpoint,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      null,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<T>>> multiPartPost<T>(
    String endpoint, {
    required FormData data,
    void Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? timeoutMergedOptions = _mergeOptionsWithRequestId(
      baseOptions,
    );
    final Options mergedOptions = _mergeMultipartOptions(timeoutMergedOptions);
    return _executeRequest<T>(
      () => _dio.post(
        endpoint,
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      fromJson,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<T>>> multiPartPatch<T>(
    String endpoint, {
    required FormData data,
    void Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? timeoutMergedOptions = _mergeOptionsWithRequestId(
      baseOptions,
    );
    final Options mergedOptions = _mergeMultipartOptions(timeoutMergedOptions);
    return _executeRequest<T>(
      () => _dio.patch(
        endpoint,
        data: data,
        onSendProgress: onSendProgress,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      fromJson,
    );
  }

  @override
  Future<Either<Failure, BaseResponse<void>>> download(
    String url,
    String path, {
    void Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final Options? baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final Options? mergedOptions = _mergeOptionsWithRequestId(baseOptions);
    return _executeRequest<void>(
      () => _dio.download(
        url,
        path,
        onReceiveProgress: onReceiveProgress,
        cancelToken: cancelToken,
        options: mergedOptions,
      ),
      null,
    );
  }

  /// Merges multipart-specific options with provided options
  /// Performance: Efficient map merging
  /// Preserves request ID from provided options
  Options _mergeMultipartOptions(Options? providedOptions) {
    const Duration baseSendTimeout = Duration(seconds: 60);
    const Duration baseReceiveTimeout = Duration(seconds: 60);

    final Options baseOptions = Options(
      sendTimeout: baseSendTimeout,
      receiveTimeout: baseReceiveTimeout,
      contentType: 'multipart/form-data',
    );

    if (providedOptions == null) {
      return baseOptions;
    }

    // Merge headers maps
    final Map<String, dynamic> mergedHeaders = <String, dynamic>{};
    if (baseOptions.headers != null) {
      mergedHeaders.addAll(baseOptions.headers!);
    }
    if (providedOptions.headers != null) {
      mergedHeaders.addAll(providedOptions.headers!);
    }

    // Merge extra maps (preserves requestId from providedOptions)
    final Map<String, dynamic> mergedExtra = <String, dynamic>{};
    if (baseOptions.extra != null) {
      mergedExtra.addAll(baseOptions.extra!);
    }
    if (providedOptions.extra != null) {
      mergedExtra.addAll(providedOptions.extra!);
    }

    // Merge provided options with base options
    return Options(
      method: providedOptions.method ?? baseOptions.method,
      sendTimeout: providedOptions.sendTimeout ?? baseOptions.sendTimeout,
      receiveTimeout:
          providedOptions.receiveTimeout ?? baseOptions.receiveTimeout,
      extra: mergedExtra.isEmpty ? null : mergedExtra,
      headers: mergedHeaders.isEmpty ? null : mergedHeaders,
      responseType: providedOptions.responseType ?? baseOptions.responseType,
      validateStatus:
          providedOptions.validateStatus ?? baseOptions.validateStatus,
      receiveDataWhenStatusError:
          providedOptions.receiveDataWhenStatusError ??
          baseOptions.receiveDataWhenStatusError,
      followRedirects:
          providedOptions.followRedirects ?? baseOptions.followRedirects,
      maxRedirects: providedOptions.maxRedirects ?? baseOptions.maxRedirects,
      requestEncoder:
          providedOptions.requestEncoder ?? baseOptions.requestEncoder,
      responseDecoder:
          providedOptions.responseDecoder ?? baseOptions.responseDecoder,
      listFormat: providedOptions.listFormat ?? baseOptions.listFormat,
      contentType: 'multipart/form-data',
    );
  }

  /// Execute request with error handling
  /// Performance: Relies on Dio's native error handling for connectivity issues
  /// rather than performing a blocking pre-flight check
  Future<Either<Failure, BaseResponse<T>>> _executeRequest<T>(
    Future<Response<dynamic>> Function() request,
    T Function(Object?)? fromJson,
  ) async {
    try {
      final Response<dynamic> response = await request();
      final BaseResponse<T> baseResponse = _responseParser.parse<T>(
        response,
        fromJson,
      );
      return _validateResponse<T>(baseResponse);
    } on DioException catch (e) {
      final Failure failure = _errorHandler.handleDioException(e);
      return Left<Failure, BaseResponse<T>>(failure);
    } on Object catch (e) {
      final Unexpected failure = Unexpected(message: 'Unexpected error: $e');
      return Left<Failure, BaseResponse<T>>(failure);
    }
  }

  Either<Failure, BaseResponse<T>> _validateResponse<T>(
    BaseResponse<T> response,
  ) {
    return _errorHandler.validateResponse<T>(response);
  }
}
