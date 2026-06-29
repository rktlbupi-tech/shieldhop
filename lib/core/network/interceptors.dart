import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/firebase_logger.dart';

class AuthInterceptor extends Interceptor {
  final SharedPreferences prefs;

  AuthInterceptor(this.prefs);

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    final token = prefs.getString('auth_token');
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      prefs.remove('auth_token');
      // TODO: navigate to login (use global navigator key)
    }
    handler.next(err);
  }
}

/// Clean, single-line network logging — no ANSI boxes, no escape-code noise.
///   →  GET  /enterprise/tasks?…
///   ←  200  GET /enterprise/tasks  (123ms)
///   ✖  500  POST /enterprise/…     error
class AppLogInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.extra['__startMs'] = DateTime.now().millisecondsSinceEpoch;
    FirebaseLogger.logMessage(
      'API_REQ: ${options.method} ${_short(options.uri)}',
    );
    if (kDebugMode) {
      debugPrint('→  ${options.method.padRight(4)} ${_short(options.uri)}');
      final body = _formatBody(options.data);
      if (body != null) debugPrint('   body: $body');
    }
    handler.next(options);
  }

  @override
  void onResponse(Response response, ResponseInterceptorHandler handler) {
    final o = response.requestOptions;
    FirebaseLogger.logMessage(
      'API_RESP: ${response.statusCode} ${o.method} ${_short(o.uri)}${_elapsed(o)}',
    );
    if (kDebugMode) {
      debugPrint(
        '←  ${response.statusCode}  ${o.method.padRight(4)} ${_short(o.uri)}${_elapsed(o)}',
      );
      final body = _formatBody(response.data);
      if (body != null) debugPrint('   resp: $body');
    }
    handler.next(response);
  }

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    final o = err.requestOptions;
    final status = err.response?.statusCode ?? '---';
    final shortUri = _short(o.uri);
    final elapsed = _elapsed(o);

    FirebaseLogger.logMessage(
      'API_ERR: $status ${o.method} $shortUri$elapsed | error: ${err.message}',
    );

    if (kDebugMode) {
      debugPrint('✖  $status  ${o.method.padRight(4)} $shortUri$elapsed');
      if (err.message != null) debugPrint('   error: ${err.message}');
      final data = err.response?.data;
      if (data != null) {
        debugPrint('   resp:  ${_truncate(data.toString(), 500)}');
      }
    }
    handler.next(err);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  String _short(Uri uri) {
    final q = uri.query.isNotEmpty ? '?${uri.query}' : '';
    return '${uri.path}$q';
  }

  String _elapsed(RequestOptions o) {
    final start = o.extra['__startMs'];
    if (start is int) {
      return '  (${DateTime.now().millisecondsSinceEpoch - start}ms)';
    }
    return '';
  }

  String? _formatBody(dynamic data) {
    if (data == null) return null;
    if (data is FormData) {
      final fields = {for (final f in data.fields) f.key: f.value};
      final files = data.files.map((e) => e.value.filename ?? 'file').toList();
      return 'FormData fields=$fields files=$files';
    }
    try {
      return _truncate(const JsonEncoder.withIndent('  ').convert(data), 1000);
    } catch (_) {
      return _truncate(data.toString(), 1000);
    }
  }

  String _truncate(String s, int max) => s;
}
