import 'package:dio/dio.dart';
import '../models/base_response.dart';

/// Abstract response parser interface
/// Allows different API response formats to be supported by providing
/// different parser implementations following Dependency Inversion Principle
abstract class ResponseParser {
  /// Parse a Dio Response into a BaseResponse
  ///
  /// [response] is the raw Dio response
  /// [fromJson] is the optional function to deserialize the data field
  /// Returns a BaseResponse with parsed data
  BaseResponse<T> parse<T>(Response response, T Function(Object?)? fromJson);
}
