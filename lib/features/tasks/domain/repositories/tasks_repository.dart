import '../../../../core/errors/failures.dart';
import '../entities/task_entity.dart';

abstract class TasksRepository {
  Future<(List<TaskEntity>, Failure?)> fetchTasks({int page = 1, int limit = 20});
  Future<(TaskEntity?, Failure?)> fetchTaskDetails(String taskId);
  Future<(bool, Failure?)> updateTaskStatus(String taskId, String status);
}
