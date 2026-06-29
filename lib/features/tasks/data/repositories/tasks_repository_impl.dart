import '../../../../core/errors/failures.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/tasks_repository.dart';
import '../datasources/tasks_remote_datasource.dart';

class TasksRepositoryImpl implements TasksRepository {
  final TasksRemoteDatasource _ds;
  TasksRepositoryImpl(this._ds);

  @override
  Future<(List<TaskEntity>, Failure?)> fetchTasks({int page = 1, int limit = 20}) async {
    try {
      final models = await _ds.fetchTasks(page: page, limit: limit);
      return (models.map((m) => m.toEntity()).toList(), null);
    } on Failure catch (f) { return (<TaskEntity>[], f); }
    catch (e) { return (<TaskEntity>[], UnknownFailure(e.toString())); }
  }

  @override
  Future<(TaskEntity?, Failure?)> fetchTaskDetails(String taskId) async {
    try { return ((await _ds.fetchTaskDetails(taskId)).toEntity(), null); }
    on Failure catch (f) { return (null, f); }
    catch (e) { return (null, UnknownFailure(e.toString())); }
  }

  @override
  Future<(bool, Failure?)> updateTaskStatus(String taskId, String status) async {
    try { return (await _ds.updateTaskStatus(taskId, status), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }
}
