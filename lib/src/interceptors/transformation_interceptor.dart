import 'package:dio/dio.dart';
import '../contracts/transformation_hooks.dart';

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
      } catch (e) {
        // If transformation fails, pass error to handler
        handler.reject(
          DioException(
            requestOptions: options,
            error: e,
            type: DioExceptionType.unknown,
            message: 'Request transformation failed: $e',
          ),
          true,
        );
        return;
      }
    }

    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    // Apply response transformation if hook is provided
    if (hooks.onResponseTransform != null) {
      try {
        final transformedData = hooks.onResponseTransform!(
          response.requestOptions.path,
          response,
        );

        // Create new response with transformed data
        final transformedResponse = Response(
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
      } catch (e) {
        // If transformation fails, pass error to handler
        handler.reject(
          DioException(
            requestOptions: response.requestOptions,
            response: response,
            error: e,
            type: DioExceptionType.unknown,
            message: 'Response transformation failed: $e',
          ),
          true,
        );
        return;
      }
    }

    handler.next(response);
  }
}
