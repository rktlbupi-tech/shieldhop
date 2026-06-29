import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/task_model.dart';

class TasksRemoteDatasource {
  final ApiClient _client;
  TasksRemoteDatasource(this._client);

  Future<List<TaskModel>> fetchTasks({int page = 1, int limit = 20}) async {
    final res = await _client.get(ApiEndpoints.tasks,
        queryParameters: {'page': page, 'limit': limit, 'sortBy': 'createdAt', 'sortOrder': 'desc'});
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data.map((e) => TaskModel.fromJson(e as Map<String, dynamic>)).toList();
  }

  Future<TaskModel> fetchTaskDetails(String taskId) async {
    final res = await _client.get('${ApiEndpoints.taskDetails}$taskId');
    final data = res.data['data'] as Map<String, dynamic>? ?? res.data as Map<String, dynamic>;
    return TaskModel.fromJson(data);
  }

  Future<bool> updateTaskStatus(String taskId, String status) async {
    final res = await _client.patch('${ApiEndpoints.taskDetails}$taskId',
        data: {'status': status});
    return res.data['success'] == true;
  }
}
