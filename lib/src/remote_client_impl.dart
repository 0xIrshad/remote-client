import 'dart:math';
import 'package:dio/dio.dart';
import 'contracts/remote_client.dart';
import 'contracts/connectivity_service.dart';
import 'contracts/error_handler.dart';
import 'contracts/response_parser.dart';
import 'models/base_response.dart';
import 'models/request_timeout_config.dart';
import 'types/either.dart';
import 'types/failure.dart';
import 'services/response_parser_impl.dart';

/// High-performance HTTP client implementation
/// Performance optimizations:
/// - Connection pooling via Dio
/// - Efficient error handling
/// - Minimal object allocation
/// - Optimized request execution
/// - Request ID tracking for debugging
class RemoteClientImpl implements RemoteClient {
  final Dio _dio;
  final ConnectivityService _connectivityService;
  final ErrorHandler _errorHandler;
  final ResponseParser _responseParser;
  final bool _enableRequestId;
  final _random = Random();

  // Request ID generation state for better uniqueness
  // Using a counter to ensure uniqueness even within the same millisecond
  int _requestIdCounter = 0;
  int _lastTimestamp = 0;

  RemoteClientImpl({
    required Dio dio,
    required ConnectivityService connectivityService,
    required ErrorHandler errorHandler,
    ResponseParser? responseParser,
    bool enableRequestId = true,
  }) : _dio = dio,
       _connectivityService = connectivityService,
       _errorHandler = errorHandler,
       _responseParser = responseParser ?? const DefaultResponseParser(),
       _enableRequestId = enableRequestId;

  /// Generate a unique request ID for tracking
  /// Uses timestamp + counter + random for better uniqueness and efficiency
  /// Format: timestamp_counter_random (e.g., 1234567890_1234_5678)
  String _generateRequestId() {
    if (!_enableRequestId) return '';

    final timestamp = DateTime.now().millisecondsSinceEpoch;

    // Reset counter if timestamp changed (new millisecond)
    if (timestamp != _lastTimestamp) {
      _requestIdCounter = 0;
      _lastTimestamp = timestamp;
    } else {
      // Increment counter for same millisecond
      _requestIdCounter++;
    }

    // Generate random component (4 digits for compactness)
    final random = _random.nextInt(10000);

    // Combine: timestamp_counter_random
    return '${timestamp}_${_requestIdCounter}_$random';
  }

  /// Merge options with request ID if enabled
  Options? _mergeOptionsWithRequestId(Options? options) {
    if (!_enableRequestId) return options;

    final requestId = _generateRequestId();
    final extra = <String, dynamic>{...?options?.extra, 'requestId': requestId};

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
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final mergedOptions = _mergeOptionsWithRequestId(baseOptions);
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
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final mergedOptions = _mergeOptionsWithRequestId(baseOptions);
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
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final mergedOptions = _mergeOptionsWithRequestId(baseOptions);
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
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final mergedOptions = _mergeOptionsWithRequestId(baseOptions);
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
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final mergedOptions = _mergeOptionsWithRequestId(baseOptions);
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
    Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final timeoutMergedOptions = _mergeOptionsWithRequestId(baseOptions);
    final mergedOptions = _mergeMultipartOptions(timeoutMergedOptions);
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
    Function(int, int)? onSendProgress,
    T Function(Object?)? fromJson,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final timeoutMergedOptions = _mergeOptionsWithRequestId(baseOptions);
    final mergedOptions = _mergeMultipartOptions(timeoutMergedOptions);
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
    Function(int, int)? onReceiveProgress,
    CancelToken? cancelToken,
    Options? options,
    RequestTimeoutConfig? timeout,
  }) async {
    final baseOptions = timeout?.mergeWithOptions(options) ?? options;
    final mergedOptions = _mergeOptionsWithRequestId(baseOptions);
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
    const baseSendTimeout = Duration(seconds: 60);
    const baseReceiveTimeout = Duration(seconds: 60);

    final baseOptions = Options(
      sendTimeout: baseSendTimeout,
      receiveTimeout: baseReceiveTimeout,
      contentType: 'multipart/form-data',
    );

    if (providedOptions == null) {
      return baseOptions;
    }

    // Merge headers maps
    final mergedHeaders = <String, dynamic>{};
    if (baseOptions.headers != null) {
      mergedHeaders.addAll(baseOptions.headers!);
    }
    if (providedOptions.headers != null) {
      mergedHeaders.addAll(providedOptions.headers!);
    }

    // Merge extra maps (preserves requestId from providedOptions)
    final mergedExtra = <String, dynamic>{};
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

  /// Execute request with error handling and connectivity check
  /// Performance: Early exit on connectivity failure, efficient error handling
  Future<Either<Failure, BaseResponse<T>>> _executeRequest<T>(
    Future<Response> Function() request,
    T Function(Object?)? fromJson,
  ) async {
    // Performance: Check connectivity first to avoid unnecessary network calls
    if (!await _connectivityService.isConnected()) {
      return const Left(NoInternet(message: 'No internet connection'));
    }

    try {
      final response = await request();
      final baseResponse = _responseParser.parse<T>(response, fromJson);
      return _validateResponse<T>(baseResponse);
    } on DioException catch (e) {
      final failure = _errorHandler.handleDioException(e);
      return Left(failure);
    } catch (e) {
      final failure = Unexpected(message: 'Unexpected error: $e');
      return Left(failure);
    }
  }

  Either<Failure, BaseResponse<T>> _validateResponse<T>(
    BaseResponse<T> response,
  ) {
    return _errorHandler.validateResponse<T>(response);
  }
}
