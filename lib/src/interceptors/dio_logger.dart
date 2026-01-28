import 'dart:developer' as developer;
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:dio/dio.dart';

const String _timeStampKey = '_pdl_timeStamp_';

class _Colors {
  static const String reset = '\x1B[0m';
  static const String green = '\x1B[32m';
  static const String red = '\x1B[31m';
  static const String cyan = '\x1B[36m';
  static const String white = '\x1B[37m';
  static const String brightCyan = '\x1B[96m';
  static const String bold = '\x1B[1m';
}

class DioLogger extends Interceptor {
  final bool request;
  final bool requestHeader;
  final bool requestBody;
  final bool responseBody;
  final bool responseHeader;
  final bool error;
  static const int kInitialTab = 1;
  static const String tabStep = '    ';
  final bool compact;
  final int maxWidth;
  static const int chunkSize = 20;
  final void Function(String message, {String? name}) logPrint;
  final bool Function(RequestOptions options, FilterArgs args)? filter;
  final bool enabled;
  final bool enableColors;

  DioLogger({
    this.request = true,
    this.requestHeader = false,
    this.requestBody = false,
    this.responseHeader = false,
    this.responseBody = true,
    this.error = true,
    this.maxWidth = 90,
    this.compact = true,
    this.logPrint = _defaultLog,
    this.filter,
    this.enabled = true,
    this.enableColors = true,
  });

  static void _defaultLog(String message, {String? name}) {
    developer.log(message, name: name ?? 'DioLogger');
  }

  String _colorize(String text, String color) {
    if (!enableColors) return text;
    return '$color$text${_Colors.reset}';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final Map<String, dynamic> extra = Map<String, dynamic>.of(options.extra);
    options.extra[_timeStampKey] = DateTime.timestamp().millisecondsSinceEpoch;

    if (!enabled ||
        (filter != null && !filter!(options, FilterArgs(isResponse: false, data: options.data)))) {
      handler.next(options);
      return;
    }

    if (request) {
      _printRequestHeader(options);
    }
    if (requestHeader) {
      _printMapAsTable(
        options.queryParameters,
        header: 'Query Parameters',
        color: _Colors.green,
      );
      final Map<String, dynamic> requestHeaders = <String, dynamic>{}..addAll(options.headers);
      if (options.contentType != null) {
        requestHeaders['contentType'] = options.contentType?.toString();
      }
      requestHeaders['responseType'] = options.responseType.toString();
      requestHeaders['followRedirects'] = options.followRedirects;
      if (options.connectTimeout != null) {
        requestHeaders['connectTimeout'] = options.connectTimeout?.toString();
      }
      if (options.receiveTimeout != null) {
        requestHeaders['receiveTimeout'] = options.receiveTimeout?.toString();
      }
      _printMapAsTable(requestHeaders, header: 'Headers', color: _Colors.green);
      _printMapAsTable(extra, header: 'Extras', color: _Colors.green);
    }
    if (requestBody && options.method != 'GET') {
      final dynamic data = options.data;
      if (data != null) {
        if (data is Map) {
          _printMapAsTable(
            options.data as Map<String, dynamic>?,
            header: 'Body 🚀',
            color: _Colors.green,
            ht: true,
          );
        } else if (data is FormData) {
          final Map<String, dynamic> formDataMap = <String, dynamic>{}
            ..addEntries(data.fields)
            ..addEntries(data.files);
          _printMapAsTable(
            formDataMap,
            header: 'Form data | ${data.boundary}',
            color: _Colors.green,
          );
        } else {
          _printBlock(data.toString(), color: _Colors.green);
        }
      }
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (!enabled ||
        (filter != null &&
            !filter!(
              err.requestOptions,
              FilterArgs(isResponse: true, data: err.response?.data),
            ))) {
      handler.next(err);
      return;
    }

    final Object? triggerTime = err.requestOptions.extra[_timeStampKey];

    if (error) {
      if (err.type == DioExceptionType.badResponse) {
        final Uri? uri = err.response?.requestOptions.uri;
        int diff = 0;
        if (triggerTime is int) {
          diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
        }
        const String blink = '\x1B[5m';

        _printBoxed(
          header:
              '$blink DioError 🚨 Status: ${err.response?.statusCode} ${err.response?.statusMessage} ║ Time: $diff ms',
          text: uri.toString(),
          color: _Colors.red,
        );
        if (err.response != null && err.response?.data != null) {
          logPrint(_colorize('╔ ${err.type}', _Colors.red));
          _printResponse(err.response!, color: _Colors.red);
        }
        _printLine(color: _Colors.red);
        logPrint('');
      } else {
        _printBoxed(
          header: 'DioError ║ ${err.type}',
          text: err.message,
          color: _Colors.red,
        );
      }
    }
    handler.next(err);
  }

  @override
  void onResponse(Response<dynamic> response, ResponseInterceptorHandler handler) {
    if (!enabled ||
        (filter != null &&
            !filter!(
              response.requestOptions,
              FilterArgs(isResponse: true, data: response.data),
            ))) {
      handler.next(response);
      return;
    }

    final Object? triggerTime = response.requestOptions.extra[_timeStampKey];

    int diff = 0;
    if (triggerTime is int) {
      diff = DateTime.timestamp().millisecondsSinceEpoch - triggerTime;
    }
    _printResponseHeader(response, diff);
    if (responseHeader) {
      final Map<String, String> responseHeaders = <String, String>{};
      response.headers.forEach(
        (String k, List<String> list) => responseHeaders[k] = list.toString(),
      );
      _printMapAsTable(
        responseHeaders,
        header: 'Headers',
        color: _Colors.green,
      );
    }

    if (responseBody) {
      logPrint(_colorize('╔ Body', _Colors.white));
      logPrint(_colorize('║', _Colors.white));
      _printResponse(response);
      logPrint(_colorize('║', _Colors.white));
      _printLine();
    }
    handler.next(response);
  }

  void _printBoxed({
    String? header,
    String? text,
    String color = _Colors.white,
  }) {
    logPrint('');
    logPrint(_colorize('╔╣ $header', color));
    logPrint(_colorize('║  $text', color));
    _printLine(color: color);
  }

  void _printResponse(Response<dynamic> response, {String color = _Colors.white}) {
    if (response.data != null) {
      if (response.data is Map) {
        _printPrettyMap(response.data as Map<dynamic, dynamic>, color: color);
      } else if (response.data is Uint8List) {
        logPrint(_colorize('║${_indent()}[', color));
        _printUint8List(response.data as Uint8List, color: color);
        logPrint(_colorize('║${_indent()}]', color));
      } else if (response.data is List) {
        logPrint(_colorize('║${_indent()}[', color));
        _printList(response.data as List<dynamic>, color: color);
        logPrint(_colorize('║${_indent()}]', color));
      } else {
        _printBlock(response.data.toString(), color: color);
      }
    }
  }

  void _printResponseHeader(Response<dynamic> response, int responseTime) {
    final Uri uri = response.requestOptions.uri;
    final String method = response.requestOptions.method;
    final String statusColor =
        (response.statusCode != null && response.statusCode! >= 200 && response.statusCode! < 300)
        ? _Colors.green
        : _Colors.red;

    _printBoxed(
      header:
          'Response ║ $method ║ Status: ${response.statusCode} ${response.statusMessage}  ║ Time: $responseTime ms',
      text: uri.toString(),
      color: statusColor,
    );
  }

  void _printRequestHeader(RequestOptions options) {
    final Uri uri = options.uri;
    final String method = options.method;
    _printBoxed(
      header: 'Request ║ $method ',
      text: uri.toString(),
      color: _Colors.cyan,
    );
  }

  void _printLine({
    String pre = '',
    String suf = '╝',
    String color = _Colors.white,
  }) => logPrint(_colorize('$pre${'═' * maxWidth}$suf', color));

  void _printKV(String? key, Object? v, {String color = _Colors.white}) {
    final String pre = '╟ $key: ';
    final String msg = v.toString();

    if (pre.length + msg.length > maxWidth) {
      logPrint(_colorize(pre, color));
      _printBlock(msg, color: color);
    } else {
      logPrint(_colorize('$pre$msg', color));
    }
  }

  void _printBlock(String msg, {String color = _Colors.white}) {
    final int lines = (msg.length / maxWidth).ceil();
    for (int i = 0; i < lines; ++i) {
      logPrint(
        _colorize(
          (i >= 0 ? '║ ' : '') +
              msg.substring(
                i * maxWidth,
                math.min<int>(i * maxWidth + maxWidth, msg.length),
              ),
          color,
        ),
      );
    }
  }

  String _indent([int tabCount = kInitialTab]) => tabStep * tabCount;

  void _printPrettyMap(
    Map<dynamic, dynamic> data, {
    int initialTab = kInitialTab,
    bool isListItem = false,
    bool isLast = false,
    String color = _Colors.white,
  }) {
    int tabs = initialTab;
    final bool isRoot = tabs == kInitialTab;
    final String initialIndent = _indent(tabs);
    tabs++;

    if (isRoot || isListItem) logPrint(_colorize('║$initialIndent{', color));

    for (int index = 0; index < data.length; index++) {
      final bool isLast = index == data.length - 1;
      final String key = '"${data.keys.elementAt(index)}"';
      dynamic value = data[data.keys.elementAt(index)];
      if (value is String) {
        value = '"${value.replaceAll(RegExp(r'([\r\n])+'), " ")}"';
      }
      if (value is Map) {
        if (compact && _canFlattenMap(value)) {
          logPrint(
            _colorize(
              '║${_indent(tabs)} $key: $value${!isLast ? ',' : ''}',
              color,
            ),
          );
        } else {
          logPrint(_colorize('║${_indent(tabs)} $key: {', color));
          _printPrettyMap(value, initialTab: tabs, color: color);
        }
      } else if (value is List) {
        if (compact && _canFlattenList(value)) {
          logPrint(
            _colorize('║${_indent(tabs)} $key: $value', color),
          );
        } else {
          logPrint(_colorize('║${_indent(tabs)} $key: [', color));
          _printList(value, tabs: tabs, color: color);
          logPrint(_colorize('║${_indent(tabs)} ]${isLast ? '' : ','}', color));
        }
      } else {
        final String msg = value.toString().replaceAll('\n', '');
        final String indent = _indent(tabs);
        final int linWidth = maxWidth - indent.length;
        if (msg.length + indent.length > linWidth) {
          final int lines = (msg.length / linWidth).ceil();
          for (int i = 0; i < lines; ++i) {
            final String multilineKey = i == 0 ? '$key:' : '';
            logPrint(
              _colorize(
                '║${_indent(tabs)} $multilineKey ${msg.substring(i * linWidth, math.min<int>(i * linWidth + linWidth, msg.length))}',
                color,
              ),
            );
          }
        } else {
          logPrint(
            _colorize(
              '║${_indent(tabs)} $key: $msg${!isLast ? ',' : ''}',
              color,
            ),
          );
        }
      }
    }

    logPrint(
      _colorize('║$initialIndent}${isListItem && !isLast ? ',' : ''}', color),
    );
  }

  void _printList(
    List<dynamic> list, {
    int tabs = kInitialTab,
    String color = _Colors.white,
  }) {
    for (int i = 0; i < list.length; i++) {
      final dynamic element = list[i];
      final bool isLast = i == list.length - 1;
      if (element is Map) {
        if (compact && _canFlattenMap(element)) {
          logPrint(
            _colorize(
              '║${_indent(tabs)}  $element${!isLast ? ',' : ''}',
              color,
            ),
          );
        } else {
          _printPrettyMap(
            element,
            initialTab: tabs + 1,
            isListItem: true,
            isLast: isLast,
            color: color,
          );
        }
      } else {
        logPrint(
          _colorize(
            '║${_indent(tabs + 2)} $element${isLast ? '' : ','}',
            color,
          ),
        );
      }
    }
  }

  void _printUint8List(
    Uint8List list, {
    int tabs = kInitialTab,
    String color = _Colors.white,
  }) {
    final List<Uint8List> chunks = <Uint8List>[];
    for (int i = 0; i < list.length; i += chunkSize) {
      chunks.add(
        list.sublist(
          i,
          i + chunkSize > list.length ? list.length : i + chunkSize,
        ),
      );
    }
    for (final Uint8List element in chunks) {
      logPrint(_colorize('║${_indent(tabs)} ${element.join(", ")}', color));
    }
  }

  bool _canFlattenMap(Map<dynamic, dynamic> map) {
    return map.values.where((dynamic val) => val is Map || val is List).isEmpty &&
        map.toString().length < maxWidth;
  }

  bool _canFlattenList(List<dynamic> list) {
    return list.length < 10 && list.toString().length < maxWidth;
  }

  void _printMapAsTable(
    Map<dynamic, dynamic>? map, {
    String? header,
    String color = _Colors.white,
    bool ht = false,
  }) {
    if (map == null || map.isEmpty) return;
    logPrint(_colorize('╔ $header ', color));
    for (final MapEntry<dynamic, dynamic> entry in map.entries) {
      _printKV(
        entry.key.toString(),
        ht ? '${_Colors.bold}${_Colors.brightCyan}${entry.value}' : entry.value,
        color: color,
      );
    }
    _printLine(color: color);
  }
}

class FilterArgs {
  final bool isResponse;
  final dynamic data;
  bool get hasStringData => data is String;
  bool get hasMapData => data is Map;
  bool get hasListData => data is List;
  bool get hasUint8ListData => data is Uint8List;
  bool get hasJsonData => hasMapData || hasListData;
  const FilterArgs({required this.isResponse, required this.data});
}
