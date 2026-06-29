import 'package:equatable/equatable.dart';

class TaskEntity extends Equatable {
  final String id;
  final String title;
  final String? description;
  final String status; // 'pending', 'in-progress', 'completed'
  final String priority; // 'low', 'medium', 'high'
  final DateTime? deadline;
  final String? assignedBy;
  final List<String> mediaUrls;
  final DateTime? createdAt;

  const TaskEntity({
    required this.id,
    required this.title,
    this.description,
    required this.status,
    required this.priority,
    this.deadline,
    this.assignedBy,
    this.mediaUrls = const [],
    this.createdAt,
  });

  String get displayStatus => switch (status) {
        'in-progress' => 'In Progress',
        'completed' => 'Completed',
        _ => 'Pending',
      };

  String get displayPriority =>
      priority[0].toUpperCase() + priority.substring(1);

  @override
  List<Object?> get props => [id, title, status, priority];
}
