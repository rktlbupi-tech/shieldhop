import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/duty_entities.dart';
import '../models/duty_models.dart';

class DutiesRemoteDatasource {
  final ApiClient _client;
  DutiesRemoteDatasource(this._client);

  Future<DutyCurrentModel> fetchCurrent() async {
    final res = await _client.get(ApiEndpoints.dutiesCurrent);
    return DutyCurrentModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<UpcomingShiftModel>> fetchUpcoming() async {
    final res = await _client.get(ApiEndpoints.dutiesUpcoming);
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => UpcomingShiftModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<List<TodayTaskModel>> fetchTodayTasks() async {
    final res = await _client.get(ApiEndpoints.dutiesTodayTasks);
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => TodayTaskModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<DutyHistoryModel> fetchHistory({
    DutyHistoryRange range = DutyHistoryRange.lastYear,
  }) async {
    final res = await _client.get(
      ApiEndpoints.dutiesHistory,
      queryParameters: {'range': range.value},
    );
    return DutyHistoryModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<HandoverReportModel> submitHandoverReport({
    required String siteName,
    required String details,
  }) async {
    final res = await _client.post(ApiEndpoints.dutiesHandoverReport, data: {
      'site_name': siteName,
      'details': details,
    });
    return HandoverReportModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
