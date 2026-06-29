import 'package:equatable/equatable.dart';

class NotificationEntity extends Equatable {
  final String id;
  final String title;
  final String body;
  final String type;
  final bool isRead;
  final String? imageUrl;
  final String? videoUrl;
  final String? targetId;
  final String? taskId;
  final Map<String, dynamic> metadata;
  final DateTime createdAt;

  const NotificationEntity({
    required this.id,
    required this.title,
    required this.body,
    required this.type,
    required this.isRead,
    this.imageUrl,
    this.videoUrl,
    this.targetId,
    this.taskId,
    required this.metadata,
    required this.createdAt,
  });

  NotificationEntity copyWith({bool? isRead}) {
    return NotificationEntity(
      id: id,
      title: title,
      body: body,
      type: type,
      isRead: isRead ?? this.isRead,
      imageUrl: imageUrl,
      videoUrl: videoUrl,
      targetId: targetId,
      taskId: taskId,
      metadata: metadata,
      createdAt: createdAt,
    );
  }

  @override
  List<Object?> get props => [id, title, body, type, isRead, createdAt];
}
