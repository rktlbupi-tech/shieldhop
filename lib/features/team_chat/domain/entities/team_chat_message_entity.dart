class TeamChatMessageEntity {
  final String id;
  final String? clientMessageId;
  final String senderId;
  final String senderName;
  final String senderProfileImage;
  final String text;
  final String kind;
  final DateTime createdAt;
  final List<TeamChatAttachmentEntity> attachments;

  TeamChatMessageEntity({
    required this.id,
    this.clientMessageId,
    required this.senderId,
    required this.senderName,
    required this.senderProfileImage,
    required this.text,
    required this.kind,
    required this.createdAt,
    this.attachments = const [],
  });

  bool isMyMessage(String myUserId) {
    return senderId == myUserId;
  }
}

class TeamChatAttachmentEntity {
  final String id;
  final String mediaType;
  final String url;
  final String fileName;
  final int fileSize;

  TeamChatAttachmentEntity({
    required this.id,
    required this.mediaType,
    required this.url,
    required this.fileName,
    required this.fileSize,
  });
}
