import '../../domain/entities/task_entity.dart';

class TaskModel {
  final String id;
  final String title;
  final String? description;
  final String status;
  final String priority;
  final DateTime? deadline;
  final String? assignedBy;
  final List<String> mediaUrls;
  final DateTime? createdAt;

  TaskModel({
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

  factory TaskModel.fromJson(Map<String, dynamic> j) {
    final assigned = j['assignedBy'];
    String? assignedName;
    if (assigned is Map) {
      assignedName = '${assigned['firstName'] ?? ''} ${assigned['lastName'] ?? ''}'.trim();
    } else {
      assignedName = assigned?.toString();
    }
    return TaskModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      title: j['title']?.toString() ?? '',
      description: j['description']?.toString(),
      status: j['status']?.toString() ?? 'pending',
      priority: j['priority']?.toString() ?? 'medium',
      deadline: j['deadline'] != null ? DateTime.tryParse(j['deadline'].toString()) : null,
      assignedBy: assignedName,
      mediaUrls: (j['mediaUrls'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      createdAt: j['createdAt'] != null ? DateTime.tryParse(j['createdAt'].toString()) : null,
    );
  }

  TaskEntity toEntity() => TaskEntity(
        id: id, title: title, description: description,
        status: status, priority: priority, deadline: deadline,
        assignedBy: assignedBy, mediaUrls: mediaUrls, createdAt: createdAt,
      );
}
