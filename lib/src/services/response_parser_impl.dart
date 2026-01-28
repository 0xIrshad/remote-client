import 'package:dio/dio.dart';

import 'package:remote_client/src/contracts/response_parser.dart';
import 'package:remote_client/src/models/base_response.dart';

/// Default response parser implementation
/// Expects API responses in the following format:
/// {
///   "success": bool,
///   "data": T,
///   "message": string?,
///   "meta": `Map<String, dynamic>?`
/// }
class DefaultResponseParser implements ResponseParser {
  /// Key for the data field in the response
  final String dataKey;

  /// Key for the success field in the response
  final String successKey;

  /// Key for the message field in the response
  final String messageKey;

  /// Key for the meta field in the response
  final String metaKey;

  /// Default success value if success key is not present
  final bool defaultSuccess;

  const DefaultResponseParser({
    this.dataKey = 'data',
    this.successKey = 'success',
    this.messageKey = 'message',
    this.metaKey = 'meta',
    this.defaultSuccess = true,
  });

  @override
  BaseResponse<T> parse<T>(
    Response<dynamic> response,
    T Function(Object?)? fromJson,
  ) {
    final dynamic responseData = response.data;

    // Handle case where response data is not a map
    if (responseData is! Map<String, dynamic>) {
      return BaseResponse<T>(
        statusCode: response.statusCode ?? 0,
        success: defaultSuccess,
      );
    }

    // Extract raw data
    final Object? rawData = responseData[dataKey];

    // Parse data if fromJson is provided
    T? parsedData;
    if (rawData != null && fromJson != null) {
      try {
        parsedData = fromJson(rawData);
      } on Object {
        // If parsing fails, keep data as null
        // Error handler will deal with it
        parsedData = null;
      }
    } else if (rawData != null && fromJson == null) {
      // If no fromJson provided but data exists, use raw data
      parsedData = rawData as T?;
    }

    // Extract other fields
    final bool success = responseData[successKey] as bool? ?? defaultSuccess;
    final String? message = responseData[messageKey] as String?;
    final Map<String, dynamic>? meta =
        responseData[metaKey] as Map<String, dynamic>?;

    return BaseResponse<T>(
      statusCode: response.statusCode ?? 0,
      success: success,
      data: parsedData,
      message: message,
      meta: meta,
    );
  }
}

/// Response parser for APIs that return data directly without wrapper
/// Example: API returns { "id": 1, "name": "John" } directly
class DirectResponseParser implements ResponseParser {
  const DirectResponseParser();

  @override
  BaseResponse<T> parse<T>(
    Response<dynamic> response,
    T Function(Object?)? fromJson,
  ) {
    final dynamic responseData = response.data;

    T? parsedData;
    if (responseData != null && fromJson != null) {
      try {
        parsedData = fromJson(responseData);
      } on Object {
        parsedData = null;
      }
    } else if (responseData != null) {
      parsedData = responseData as T?;
    }

    return BaseResponse<T>(
      statusCode: response.statusCode ?? 0,
      success:
          response.statusCode != null &&
          response.statusCode! >= 200 &&
          response.statusCode! < 300,
      data: parsedData,
    );
  }
}
