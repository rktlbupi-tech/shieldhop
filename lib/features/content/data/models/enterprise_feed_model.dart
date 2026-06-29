class EnterpriseFeedResponse {
  final bool success;
  final List<EnterpriseFeedItem> data;

  EnterpriseFeedResponse({required this.success, required this.data});

  factory EnterpriseFeedResponse.fromJson(Map<String, dynamic> json) {
    return EnterpriseFeedResponse(
      success: json['success'] ?? false,
      data: (json['data'] as List? ?? [])
          .map((e) => EnterpriseFeedItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EnterpriseFeedItem {
  final EnterpriseFeedTask task;
  final List<EnterpriseFeedContent> content;

  EnterpriseFeedItem({required this.task, required this.content});

  factory EnterpriseFeedItem.fromJson(Map<String, dynamic> json) {
    return EnterpriseFeedItem(
      task: EnterpriseFeedTask.fromJson(json['task'] as Map<String, dynamic>? ?? {}),
      content: (json['content'] as List? ?? [])
          .map((e) => EnterpriseFeedContent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class EnterpriseFeedTask {
  final String id;
  final String taskCode;
  final String title;
  final String description;
  final String status;
  final String priority;
  final String createdAt;

  EnterpriseFeedTask({
    required this.id,
    required this.taskCode,
    required this.title,
    required this.description,
    required this.status,
    required this.priority,
    required this.createdAt,
  });

  factory EnterpriseFeedTask.fromJson(Map<String, dynamic> json) {
    return EnterpriseFeedTask(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      taskCode: json['taskCode']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      priority: json['priority']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}

class EnterpriseFeedContent {
  final String id;
  final String evidenceType;
  final String previewUrl;
  final String title;
  final String description;
  final String capturedAt;
  final String captureAddressLine1;
  final String createdAt;

  EnterpriseFeedContent({
    required this.id,
    required this.evidenceType,
    required this.previewUrl,
    required this.title,
    required this.description,
    required this.capturedAt,
    required this.captureAddressLine1,
    required this.createdAt,
  });

  factory EnterpriseFeedContent.fromJson(Map<String, dynamic> json) {
    final address = json['captureAddress'] as Map<String, dynamic>? ?? {};
    return EnterpriseFeedContent(
      id: json['id']?.toString() ?? json['_id']?.toString() ?? '',
      evidenceType: json['evidenceType']?.toString() ?? 'image',
      previewUrl: json['previewUrl']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      capturedAt: json['capturedAt']?.toString() ?? '',
      captureAddressLine1: address['line1']?.toString() ?? json['description']?.toString() ?? '',
      createdAt: json['createdAt']?.toString() ?? '',
    );
  }
}
