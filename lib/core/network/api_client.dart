import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../errors/failures.dart';
import 'interceptors.dart';
import 'token_interceptor.dart';

class ApiClient {
  late final Dio _dio;

  ApiClient(SharedPreferences prefs) {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
        headers: {'Content-Type': 'application/json'},
      ),
    );
    _dio.interceptors.addAll([
      TokenInterceptor(prefs),
      AuthInterceptor(prefs),
      AppLogInterceptor(),
    ]);
  }

  Future<Response> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      return await _dio.get(path, queryParameters: queryParameters);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> post(
    String path, {
    dynamic data,
    ProgressCallback? onSendProgress,
  }) async {
    try {
      return await _dio.post(path, data: data, onSendProgress: onSendProgress);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> patch(String path, {dynamic data}) async {
    try {
      return await _dio.patch(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> put(String path, {dynamic data}) async {
    try {
      return await _dio.put(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Future<Response> delete(String path, {dynamic data}) async {
    try {
      return await _dio.delete(path, data: data);
    } on DioException catch (e) {
      throw _mapError(e);
    }
  }

  Failure _mapError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
        return const NetworkFailure('Connection timed out.');
      case DioExceptionType.connectionError:
        return const NetworkFailure();
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message =
            e.response?.data?['message'] as String? ?? 'Server error occurred.';
        if (statusCode == 401) return UnauthorizedFailure(message);
        if (statusCode == 404) return NotFoundFailure(message);
        return ServerFailure(message);
      default:
        return const UnknownFailure();
    }
  }
}
