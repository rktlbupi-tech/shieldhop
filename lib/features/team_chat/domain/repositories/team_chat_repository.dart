import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../entities/chat_conversation_entity.dart';
import '../entities/colleague_entity.dart';
import '../entities/team_chat_message_entity.dart';

abstract class TeamChatRepository {
  Future<(List<TeamChatMessageEntity>?, Failure?)> getMessages(
    String conversationId, {
    int limit = 50,
  });

  // ── Peer chat — see docs/api/peer-chat.md ──────────────────────────────────

  Future<(ColleaguesPage?, Failure?)> getColleagues({
    String? search,
    int page = 1,
    int limit = 20,
  });

  Future<(List<ChatConversationEntity>?, Failure?)> getConversations({
    String? chatMode,
    int limit = 20,
    String? cursor,
  });

  /// Create a direct (one member) or group (title + members) chat.
  /// [fallbackTitle]/[fallbackAvatar] label the returned conversation when the
  /// create response omits display info.
  Future<(ChatConversationEntity?, Failure?)> createConversation({
    required String channelType,
    String? title,
    required List<String> memberIds,
    String fallbackTitle = '',
    String fallbackAvatar = '',
  });

  Future<(List<String>?, Failure?)> prepareAndUploadMedia({
    required String conversationId,
    required List<File> files,
    void Function(double)? onProgress,
  });

  void connectSocket(String token);

  void subscribeToConversation(
    String conversationId, {
    required void Function(List<TeamChatMessageEntity> messages) onMessagesSynced,
  });

  void unsubscribeFromConversation(String conversationId);

  void listenToMessages({
    required void Function(TeamChatMessageEntity message) onNewMessage,
  });

  void stopListeningToMessages();

  void listenToTyping({
    required void Function(String actorId, String userName) onTypingStart,
    required void Function(String actorId) onTypingStop,
  });

  void stopListeningToTyping();

  void sendMessage({
    required String conversationId,
    required String text,
    List<String>? mediaAssetIds,
    required void Function(bool success, String? error) onResult,
  });

  void emitTypingStart(String conversationId, String myId, String myName);

  void emitTypingStop(String conversationId, String myId);
}
