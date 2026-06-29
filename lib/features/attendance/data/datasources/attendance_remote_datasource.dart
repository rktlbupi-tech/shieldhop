import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/attendance_model.dart';

class AttendanceRemoteDatasource {
  final ApiClient _client;
  AttendanceRemoteDatasource(this._client);

  Future<bool> checkIn(double lat, double lng) async {
    final res = await _client.post(ApiEndpoints.checkIn,
        data: {'latitude': lat, 'longitude': lng});
    return res.data['success'] == true;
  }

  /// Uploads the uniform selfie and returns its hosted URL.
  Future<String> uploadSelfie(File file) async {
    final fileName = p.basename(file.path);
    final form = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path, filename: fileName),
      'path': 'attendance',
    });
    final res = await _client.post(ApiEndpoints.uploadUserMedia, data: form);
    final data = res.data;
    String? url = data['mediaurl'] ?? data['mediaUrl'];
    if (url == null && data['fileName'] != null) {
      url = AppConfig.apiBaseUrl + data['fileName'];
    }
    if (url == null || url.isEmpty) {
      throw const ServerFailure('Failed to upload selfie');
    }
    return url;
  }

  /// Single endpoint for clock_in / break_start / break_end / clock_out.
  ///
  /// Sends GPS on every punch (skipped only when coordinates are missing/zero).
  /// On a hard-geofence failure the server replies 4xx, which the [ApiClient]
  /// surfaces as a [Failure] carrying the user-facing message.
  Future<bool> punch({
    required String kind,
    double? lat,
    double? lng,
    double? accuracyMeters,
    String? photoUrl,
    DateTime? capturedAt,
  }) async {
    final body = <String, dynamic>{'kind': kind};

    final hasLocation = lat != null && lng != null && !(lat == 0 && lng == 0);
    if (hasLocation) {
      body['location'] = {
        'lat': lat,
        'lng': lng,
        if (accuracyMeters != null) 'accuracy_meters': accuracyMeters,
      };
    }
    if (photoUrl != null && photoUrl.isNotEmpty) {
      body['photo_url'] = photoUrl;
    }
    body['captured_at'] =
        (capturedAt ?? DateTime.now().toUtc()).toIso8601String();

    final res = await _client.post(ApiEndpoints.attendancePunch, data: body);
    return res.data['success'] == true;
  }

  Future<bool> checkOut(double lat, double lng) async {
    final res = await _client.post(ApiEndpoints.checkOut,
        data: {'latitude': lat, 'longitude': lng});
    return res.data['success'] == true;
  }

  /// Per-day history, newest first. [days] defaults to 30 (max 92).
  Future<List<AttendanceLogModel>> fetchLog({int days = 30}) async {
    final res = await _client.get(
      ApiEndpoints.attendanceAppLog,
      queryParameters: {'days': days},
    );
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => AttendanceLogModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// The four stat cards. See `GET enterprise/app/attendance/summary`.
  Future<AttendanceSummaryModel> fetchSummary() async {
    final res = await _client.get(ApiEndpoints.attendanceSummary);
    return AttendanceSummaryModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  /// My raised issues, newest first. [limit] defaults to 50 (max 100).
  Future<List<AttendanceIssueModel>> fetchIssues({int limit = 50}) async {
    final res = await _client.get(
      ApiEndpoints.attendanceIssues,
      queryParameters: {'limit': limit},
    );
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => AttendanceIssueModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Raise an attendance issue. [date] is YYYY-MM-DD (defaults to today on the
  /// server when omitted). Returns the created issue.
  Future<AttendanceIssueModel> raiseIssue({
    required String type,
    String? date,
    required String details,
  }) async {
    final res = await _client.post(ApiEndpoints.attendanceIssues, data: {
      'type': type,
      if (date != null) 'date': date,
      'details': details,
    });
    return AttendanceIssueModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
