import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presshop_enterprise/features/map/data/models/map_models.dart';

const String _baseUrl = 'https://dev-api.presshop.news:5019/';

class SosApiService {
  late final Dio _dio;

  SosApiService._() {
    _dio = Dio(BaseOptions(
      baseUrl: _baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 15),
      headers: {'Content-Type': 'application/json'},
    ));
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final prefs = await SharedPreferences.getInstance();
        final token = prefs.getString('auth_token') ?? '';
        if (token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ));
  }

  static final SosApiService _instance = SosApiService._();
  factory SosApiService() => _instance;

  Future<SosSession?> startSos({
    required String type,
    required double lat,
    required double lng,
    String? note,
    Map<String, dynamic>? address,
  }) async {
    try {
      final body = <String, dynamic>{'type': type, 'lat': lat, 'lng': lng};
      if (note != null && note.isNotEmpty) body['note'] = note;
      if (address != null && address.isNotEmpty) body['address'] = address;
      final response =
          await _dio.post('enterprise/sos/start', data: body);
      if (response.statusCode == 200 || response.statusCode == 201) {
        return SosSession.fromJson(response.data as Map<String, dynamic>);
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SosApiService.startSos error: $e');
    }
    return null;
  }

  Future<bool> stopSos({
    required String sessionId,
    String resolutionNote = 'I am safe now',
  }) async {
    try {
      final response = await _dio.post(
        'enterprise/sos/stop',
        data: {'sessionId': sessionId, 'resolutionNote': resolutionNote},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      if (kDebugMode) debugPrint('SosApiService.stopSos error: $e');
      return false;
    }
  }

  Future<SosSession?> checkMyState() async {
    try {
      final response = await _dio.get('enterprise/sos/me');
      if (response.statusCode == 200) {
        final data = response.data as Map<String, dynamic>;
        final sessionData = data['data'];
        if (sessionData == null) return null;
        final session =
            SosSession.fromJson(sessionData as Map<String, dynamic>);
        return session.isActive ? session : null;
      }
    } catch (e) {
      if (kDebugMode) debugPrint('SosApiService.checkMyState error: $e');
    }
    return null;
  }
}
