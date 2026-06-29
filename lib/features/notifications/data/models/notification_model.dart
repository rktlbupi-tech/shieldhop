import '../../domain/entities/notification_entity.dart';

class NotificationModel {
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

  NotificationModel({
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

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? json['_id'] ?? '',
      title: json['title'] ?? '',
      body: json['body'] ?? '',
      type: json['type'] ?? '',
      isRead: json['isRead'] ?? json['is_read'] ?? false,
      imageUrl: json['imageUrl'] ?? json['image_url'],
      videoUrl: json['videoUrl'] ?? json['video_url'],
      targetId: json['targetId'] ?? json['target_id'],
      taskId: json['taskId'] ?? json['task_id'],
      metadata: json['metadata'] ?? {},
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  NotificationEntity toEntity() => NotificationEntity(
        id: id,
        title: title,
        body: body,
        type: type,
        isRead: isRead,
        imageUrl: imageUrl,
        videoUrl: videoUrl,
        targetId: targetId,
        taskId: taskId,
        metadata: metadata,
        createdAt: createdAt,
      );
}

class NotificationListResponse {
  final List<NotificationModel> data;
  final int unreadCount;

  NotificationListResponse({
    required this.data,
    required this.unreadCount,
  });

  factory NotificationListResponse.fromJson(Map<String, dynamic> json) {
    final responseData = json['data'];
    List<dynamic> listData = [];
    int count = 0;

    if (responseData is List) {
      listData = responseData;
    } else if (responseData is Map && responseData['docs'] is List) {
      listData = responseData['docs'];
    }

    count = json['unreadCount'] ??
        json['unread_count'] ??
        (responseData is Map ? responseData['unreadCount'] ?? responseData['unread_count'] : null) ??
        json['count'] ??
        0;

    return NotificationListResponse(
      data: listData
          .map((e) => NotificationModel.fromJson(e as Map<String, dynamic>))
          .toList(),
      unreadCount: count,
    );
  }
}
