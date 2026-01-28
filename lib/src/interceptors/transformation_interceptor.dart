import 'package:dio/dio.dart';

import 'package:remote_client/src/contracts/transformation_hooks.dart';

/// Interceptor that applies request and response transformation hooks
/// Allows developers to transform data before requests and after responses
class TransformationInterceptor extends Interceptor {
  final TransformationHooks hooks;

  TransformationInterceptor({required this.hooks});

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    // Apply request transformation if hook is provided
    if (hooks.onRequestTransform != null && options.data != null) {
      try {
        options.data = hooks.onRequestTransform!(
          options.path,
          options.data,
          options,
        );
      } on Object catch (e) {
        // If transformation fails, pass error to handler
        handler.reject(
          DioException(
            requestOptions: options,
            error: e,
            message: 'Request transformation failed: $e',
          ),
        );
        return;
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(
    Response<dynamic> response,
    ResponseInterceptorHandler handler,
  ) {
    // Apply response transformation if hook is provided
    if (hooks.onResponseTransform != null) {
      try {
        final dynamic transformedData = hooks.onResponseTransform!(
          response.requestOptions.path,
          response,
        );

        // Create new response with transformed data
        final Response<dynamic> transformedResponse = Response<dynamic>(
          data: transformedData,
          headers: response.headers,
          isRedirect: response.isRedirect,
          statusCode: response.statusCode,
          statusMessage: response.statusMessage,
          redirects: response.redirects,
          extra: response.extra,
          requestOptions: response.requestOptions,
        );

        handler.resolve(transformedResponse);
        return;
      } on Object catch (e) {
        // If transformation fails, pass error to handler
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: e,
            message: 'Response transformation failed: $e',
          ),
        );
        return;
      }
    }

    handler.next(response);
  }
}
