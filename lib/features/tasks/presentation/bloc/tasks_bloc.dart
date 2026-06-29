import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/task_entity.dart';
import '../../domain/repositories/tasks_repository.dart';

// Events
abstract class TasksEvent extends Equatable {
  const TasksEvent();
  @override List<Object?> get props => [];
}
class FetchTasks extends TasksEvent { const FetchTasks(); }
class RefreshTasks extends TasksEvent { const RefreshTasks(); }
class FilterTasksByStatus extends TasksEvent {
  final String? status; // null = all
  const FilterTasksByStatus(this.status);
  @override List<Object?> get props => [status];
}
class UpdateTaskStatus extends TasksEvent {
  final String taskId, status;
  const UpdateTaskStatus(this.taskId, this.status);
  @override List<Object?> get props => [taskId, status];
}

// States
abstract class TasksState extends Equatable {
  const TasksState();
  @override List<Object?> get props => [];
}
class TasksInitial extends TasksState { const TasksInitial(); }
class TasksLoading extends TasksState { const TasksLoading(); }
class TasksLoaded extends TasksState {
  final List<TaskEntity> allTasks;
  final List<TaskEntity> filteredTasks;
  final String? activeFilter;
  const TasksLoaded({required this.allTasks, required this.filteredTasks, this.activeFilter});
  @override List<Object?> get props => [allTasks, filteredTasks, activeFilter];
}
class TasksError extends TasksState {
  final String message;
  const TasksError(this.message);
  @override List<Object?> get props => [message];
}

// BLoC
class TasksBloc extends Bloc<TasksEvent, TasksState> {
  final TasksRepository _repo;
  List<TaskEntity> _allTasks = [];

  TasksBloc(this._repo) : super(const TasksInitial()) {
    on<FetchTasks>(_onFetch);
    on<RefreshTasks>(_onFetch);
    on<FilterTasksByStatus>(_onFilter);
    on<UpdateTaskStatus>(_onUpdate);
  }

  Future<void> _onFetch(TasksEvent e, Emitter<TasksState> emit) async {
    emit(const TasksLoading());
    final (tasks, failure) = await _repo.fetchTasks();
    if (failure != null) { emit(TasksError(failure.message)); return; }
    _allTasks = tasks;
    emit(TasksLoaded(allTasks: tasks, filteredTasks: tasks));
  }

  void _onFilter(FilterTasksByStatus e, Emitter<TasksState> emit) {
    final filtered = e.status == null
        ? _allTasks
        : _allTasks.where((t) => t.status == e.status).toList();
    emit(TasksLoaded(allTasks: _allTasks, filteredTasks: filtered, activeFilter: e.status));
  }

  Future<void> _onUpdate(UpdateTaskStatus e, Emitter<TasksState> emit) async {
    final (success, failure) = await _repo.updateTaskStatus(e.taskId, e.status);
    if (failure != null || !success) return;
    _allTasks = _allTasks.map((t) => t.id == e.taskId
        ? TaskEntity(id: t.id, title: t.title, description: t.description,
            status: e.status, priority: t.priority, deadline: t.deadline,
            assignedBy: t.assignedBy, mediaUrls: t.mediaUrls, createdAt: t.createdAt)
        : t).toList();
    emit(TasksLoaded(allTasks: _allTasks, filteredTasks: _allTasks));
  }
}
