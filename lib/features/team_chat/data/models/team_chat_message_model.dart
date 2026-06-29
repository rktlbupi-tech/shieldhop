import '../../domain/entities/team_chat_message_entity.dart';

class TeamChatMessageModel extends TeamChatMessageEntity {
  TeamChatMessageModel({
    required super.id,
    super.clientMessageId,
    required super.senderId,
    required super.senderName,
    required super.senderProfileImage,
    required super.text,
    required super.kind,
    required super.createdAt,
    required List<TeamChatAttachmentModel> super.attachments,
  });

  factory TeamChatMessageModel.fromJson(Map<String, dynamic> j) {
    final senderId = j['senderId']?.toString() ??
        j['sender']?['actorId']?.toString() ??
        j['actorId']?.toString() ??
        j['senderUserId']?.toString() ??
        j['actingAsId']?.toString() ??
        '';

    final text = j['payload']?['text']?.toString() ?? j['text']?.toString() ?? '';
    final id = j['_id']?.toString() ?? j['id']?.toString() ?? j['clientMessageId']?.toString() ?? '';
    final clientMessageId = j['clientMessageId']?.toString();
    
    final senderName = j['senderDisplayName']?.toString() ??
        j['payload']?['senderDisplayName']?.toString() ??
        j['senderName']?.toString() ??
        j['sender']?['name']?.toString() ??
        '';

    final senderProfileImage = j['payload']?['senderProfileImage']?.toString() ??
        j['senderProfileImage']?.toString() ??
        j['sender']?['profileImage']?.toString() ??
        '';

    final kind = j['kind']?.toString() ?? 'text';
    final createdAt = j['createdAt'] != null
        ? DateTime.tryParse(j['createdAt'].toString()) ?? DateTime.now()
        : DateTime.now();

    final List<dynamic> rawAttachments = j['attachments'] as List<dynamic>? ?? [];
    final attachments = rawAttachments
        .map((x) => TeamChatAttachmentModel.fromJson(Map<String, dynamic>.from(x as Map)))
        .toList();

    return TeamChatMessageModel(
      id: id,
      clientMessageId: clientMessageId,
      senderId: senderId,
      senderName: senderName,
      senderProfileImage: senderProfileImage,
      text: text,
      kind: kind,
      createdAt: createdAt,
      attachments: attachments,
    );
  }

  TeamChatMessageEntity toEntity() {
    return TeamChatMessageEntity(
      id: id,
      clientMessageId: clientMessageId,
      senderId: senderId,
      senderName: senderName,
      senderProfileImage: senderProfileImage,
      text: text,
      kind: kind,
      createdAt: createdAt,
      attachments: attachments.map((a) => (a as TeamChatAttachmentModel).toEntity()).toList(),
    );
  }
}

class TeamChatAttachmentModel extends TeamChatAttachmentEntity {
  TeamChatAttachmentModel({
    required super.id,
    required super.mediaType,
    required super.url,
    required super.fileName,
    required super.fileSize,
  });

  factory TeamChatAttachmentModel.fromJson(Map<String, dynamic> j) {
    return TeamChatAttachmentModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      mediaType: j['mediaType']?.toString() ?? '',
      url: j['url']?.toString() ?? '',
      fileName: j['fileName']?.toString() ?? '',
      fileSize: (j['fileSize'] as num?)?.toInt() ?? 0,
    );
  }

  TeamChatAttachmentEntity toEntity() {
    return TeamChatAttachmentEntity(
      id: id,
      mediaType: mediaType,
      url: url,
      fileName: fileName,
      fileSize: fileSize,
    );
  }
}
