import 'dart:convert';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/config/app_config.dart';
import '../../../core/network/interceptors.dart';
import '../data/models/camera_data.dart';

class CameraTaskService {
  late final Dio _dio;

  CameraTaskService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: AppConfig.apiBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 60),
      ),
    );
    _dio.interceptors.addAll([
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('auth_token');
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
      AppLogInterceptor(),
    ]);
  }

  Future<List<CameraTaskModel>> fetchTodayTasks({
    required String startDate,
    required String endDate,
  }) async {
    try {
      final res = await _dio.get(
        'enterprise/tasks',
        queryParameters: {
          'startDate': startDate,
          'endDate': endDate,
          'limit': 50,
        },
      );
      final data = res.data['data'];
      if (data is List) {
        return data
            .map((e) => CameraTaskModel.fromJson(e as Map<String, dynamic>))
            .toList();
      }
      return [];
    } catch (_) {
      return [];
    }
  }

  Future<bool> uploadEvidence({
    required String taskId,
    required List<CameraTaskMediaData> mediaList,
    required double latitude,
    required double longitude,
    required String address,
    String? description,
    void Function(double)? onProgress,
  }) async {
    if (taskId.isEmpty) return false;
    final assignmentId = taskId;

    try {
      final files = <File>[];
      for (final media in mediaList) {
        if (media.mediaPath.startsWith('http')) continue;
        final file = File(media.mediaPath);
        if (await file.exists()) files.add(file);
      }
      if (files.isEmpty) return false;

      final captureLocation = {
        'point': {
          'type': 'Point',
          'coordinates': [longitude, latitude],
        },
      };
      final captureAddress = {
        'line1': address,
        'city': '',
        'country': '',
        'postalCode': '',
      };
      final note = (description != null && description.isNotEmpty)
          ? description
          : 'Uploaded from app';

      // ── Step 1: start  evidence session ──────────────────────────────
      final sessionRes = await _dio.post(
        'enterprise/tasks/$taskId/evidence-sessions',
        data: {
          'title': 'Task evidence batch',
          'note': note,
          'expectedFilesCount': files.length,
          'assignmentId': assignmentId,
          'capturedAt': DateTime.now().toUtc().toIso8601String(),
          'captureLocation': captureLocation,
          'captureAddress': captureAddress,
          'metadata': {
            'devicePlatform': Platform.isAndroid ? 'android' : 'ios',
            'captureMode': 'camera_or_gallery',
            'senderType': 'employee',
          },
        },
      );

      if (sessionRes.statusCode != 200 && sessionRes.statusCode != 201) {
        return false;
      }
      final sessionData = sessionRes.data['data'] ?? {};
      final sessionId = (sessionData['id'] ?? sessionData['_id'] ?? '')
          .toString();
      if (sessionRes.data['success'] != true || sessionId.isEmpty) {
        return false;
      }

      // ── Step 2: upload the files to the session ─────────────────────────
      final formData = FormData();
      for (final file in files) {
        formData.files.add(
          MapEntry('files', await MultipartFile.fromFile(file.path)),
        );
      }
      final fileMetadata = mediaList
          .where((m) => !m.mediaPath.startsWith('http'))
          .map(
            (m) => {
              'title': 'Evidence ${m.mediaPath.split('/').last}',
              'description': (description != null && description.isNotEmpty)
                  ? description
                  : 'Captured at $address',
              'assignmentId': assignmentId,
              'captureLocation': captureLocation,
              'captureAddress': captureAddress,
            },
          )
          .toList();
      formData.fields.add(MapEntry('fileMetadata', jsonEncode(fileMetadata)));

      final uploadRes = await _dio.post(
        'enterprise/evidence-sessions/$sessionId/files',
        data: formData,
        onSendProgress: (sent, total) {
          if (total > 0) onProgress?.call(sent / total);
        },
      );

      return uploadRes.statusCode == 200 || uploadRes.statusCode == 201;
    } catch (e) {
      rethrow;
    }
  }
}
