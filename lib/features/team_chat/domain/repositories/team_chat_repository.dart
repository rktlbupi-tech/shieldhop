import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../entities/team_chat_message_entity.dart';

abstract class TeamChatRepository {
  Future<(List<TeamChatMessageEntity>?, Failure?)> getMessages(
    String conversationId, {
    int limit = 50,
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
