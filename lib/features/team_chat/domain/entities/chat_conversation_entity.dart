import 'package:equatable/equatable.dart';

/// A conversation row from `GET chat-v2/conversations` (or the object returned
/// by `POST chat-v2/conversations` when a chat is created).
class ChatConversationEntity extends Equatable {
  final String id;
  final String title;
  final String subtitle;
  final String avatarImage;
  final String lastMessagePreview;
  final DateTime? lastMessageAt;
  final int unreadCount;

  /// Server `settings.metadata.chatMode` — e.g. `enterprise-org-team`,
  /// `enterprise-task-group`, `hopper-direct`. Drives the section a chat lands in.
  final String chatMode;

  /// `direct` or `group` (derived from chatMode when the server doesn't send it).
  final bool isGroup;

  const ChatConversationEntity({
    required this.id,
    this.title = '',
    this.subtitle = '',
    this.avatarImage = '',
    this.lastMessagePreview = '',
    this.lastMessageAt,
    this.unreadCount = 0,
    this.chatMode = '',
    this.isGroup = false,
  });

  bool get isOrgTeam => chatMode == 'enterprise-org-team';

  ChatConversationEntity copyWith({int? unreadCount}) {
    return ChatConversationEntity(
      id: id,
      title: title,
      subtitle: subtitle,
      avatarImage: avatarImage,
      lastMessagePreview: lastMessagePreview,
      lastMessageAt: lastMessageAt,
      unreadCount: unreadCount ?? this.unreadCount,
      chatMode: chatMode,
      isGroup: isGroup,
    );
  }

  @override
  List<Object?> get props => [
        id,
        title,
        subtitle,
        avatarImage,
        lastMessagePreview,
        lastMessageAt,
        unreadCount,
        chatMode,
        isGroup,
      ];
}
