import '../../domain/entities/chat_conversation_entity.dart';

class ChatConversationModel extends ChatConversationEntity {
  const ChatConversationModel({
    required super.id,
    super.title,
    super.subtitle,
    super.avatarImage,
    super.lastMessagePreview,
    super.lastMessageAt,
    super.unreadCount,
    super.chatMode,
    super.isGroup,
  });

  /// Parses one item of `GET chat-v2/conversations` — shape:
  /// `{ display{title,subtitle,avatarImage}, conversation{_id,lastMessagePreview,
  /// lastMessageAt,channelType,settings{metadata{chatMode}}}, membership{unreadCount} }`.
  factory ChatConversationModel.fromJson(Map<String, dynamic> j) {
    final display = _asMap(j['display']);
    final convo = _asMap(j['conversation']);
    final membership = _asMap(j['membership']);
    final settings = _asMap(convo['settings']);
    final metadata = _asMap(settings['metadata']);

    final chatMode = metadata['chatMode']?.toString() ?? '';
    final channelType = convo['channelType']?.toString() ?? '';
    final isGroup = channelType == 'group' ||
        chatMode.contains('group') ||
        chatMode == 'enterprise-org-team';

    return ChatConversationModel(
      id: (convo['_id'] ?? convo['id'] ?? '').toString(),
      title: display['title']?.toString() ?? '',
      subtitle: display['subtitle']?.toString() ?? '',
      avatarImage: display['avatarImage']?.toString() ?? '',
      lastMessagePreview: convo['lastMessagePreview']?.toString() ?? '',
      lastMessageAt: DateTime.tryParse(convo['lastMessageAt']?.toString() ?? ''),
      unreadCount: (membership['unreadCount'] as num?)?.toInt() ?? 0,
      chatMode: chatMode,
      isGroup: isGroup,
    );
  }

  /// Parses the `data` object returned by `POST chat-v2/conversations` — a raw
  /// conversation doc (id + channelType + optional title). Display/avatar come
  /// from the picker at the call site, so [fallbackTitle]/[fallbackAvatar] fill in.
  factory ChatConversationModel.fromCreated(
    Map<String, dynamic> data, {
    String fallbackTitle = '',
    String fallbackAvatar = '',
  }) {
    final channelType = data['channelType']?.toString() ?? '';
    return ChatConversationModel(
      id: (data['_id'] ?? data['id'] ?? '').toString(),
      title: data['title']?.toString().isNotEmpty == true
          ? data['title'].toString()
          : fallbackTitle,
      avatarImage: fallbackAvatar,
      isGroup: channelType == 'group',
    );
  }

  ChatConversationEntity toEntity() => ChatConversationEntity(
        id: id,
        title: title,
        subtitle: subtitle,
        avatarImage: avatarImage,
        lastMessagePreview: lastMessagePreview,
        lastMessageAt: lastMessageAt,
        unreadCount: unreadCount,
        chatMode: chatMode,
        isGroup: isGroup,
      );

  static Map<String, dynamic> _asMap(dynamic v) =>
      v is Map ? Map<String, dynamic>.from(v) : <String, dynamic>{};
}
