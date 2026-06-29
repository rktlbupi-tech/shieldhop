import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path/path.dart' as p;
import '../../../../core/config/app_config.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/leave_entities.dart';
import '../models/leave_models.dart';

class LeaveRemoteDatasource {
  final ApiClient _client;
  LeaveRemoteDatasource(this._client);

  /// Uploads a leave attachment via the shared media flow, returns its URL.
  Future<String> uploadFile(File file) async {
    final form = FormData.fromMap({
      'media': await MultipartFile.fromFile(file.path,
          filename: p.basename(file.path)),
      'path': 'leave',
    });
    final res = await _client.post(ApiEndpoints.uploadUserMedia, data: form);
    final data = res.data;
    String? url = data['mediaurl'] ?? data['mediaUrl'];
    if (url == null && data['fileName'] != null) {
      url = AppConfig.apiBaseUrl + data['fileName'];
    }
    if (url == null || url.isEmpty) {
      throw const ServerFailure('Failed to upload attachment');
    }
    return url;
  }

  Future<List<LeaveTypeEntity>> fetchTypes() async {
    final res = await _client.get(ApiEndpoints.leaveTypes);
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => leaveTypeFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<LeaveBalanceEntity>> fetchBalances() async {
    final res = await _client.get(ApiEndpoints.leaveBalances);
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => leaveBalanceFromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<LeaveRequestEntity> applyLeave({
    required String leaveTypeId,
    required String from,
    required String to,
    String halfDay = 'none',
    String reason = '',
    List<LeaveAttachment> attachments = const [],
  }) async {
    final res = await _client.post(ApiEndpoints.leave, data: {
      'leaveTypeId': leaveTypeId,
      'from': from,
      'to': to,
      'halfDay': halfDay,
      if (reason.isNotEmpty) 'reason': reason,
      if (attachments.isNotEmpty)
        'attachments': attachments.map((a) => a.toJson()).toList(),
    });
    return leaveRequestFromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LeaveRequestPage> fetchRequests({
    String? status,
    int? year,
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get(
      ApiEndpoints.leave,
      queryParameters: {
        if (status != null) 'status': status,
        if (year != null) 'year': year,
        'page': page,
        'limit': limit,
      },
    );
    return leaveRequestPageFromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LeaveRequestEntity> fetchRequest(String id) async {
    final res = await _client.get('${ApiEndpoints.leave}/$id');
    return leaveRequestFromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LeaveRequestEntity> cancelRequest(String id) async {
    final res = await _client.post('${ApiEndpoints.leave}/$id/cancel');
    return leaveRequestFromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<LeaveCalendarEntity> fetchCalendar({String? month}) async {
    final res = await _client.get(
      ApiEndpoints.leaveCalendar,
      queryParameters: {if (month != null) 'month': month},
    );
    return leaveCalendarFromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
