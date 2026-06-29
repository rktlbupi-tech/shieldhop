import 'dart:io';
import 'package:dio/dio.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/socket/socket_events.dart';
import '../../../../core/network/socket/socket_manager.dart';

class TeamChatRemoteDataSource {
  final ApiClient _client;
  TeamChatRemoteDataSource(this._client);

  Future<Map<String, dynamic>> getMessages(String conversationId, {int limit = 50}) async {
    final res = await _client.get(
      'chat-v2/conversations/$conversationId/messages',
      queryParameters: {'limit': limit},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> prepareMedia(
    String conversationId,
    List<Map<String, dynamic>> items,
  ) async {
    final res = await _client.post(
      'chat-v2/media/prepare',
      data: {'conversationId': conversationId, 'items': items},
    );
    return res.data as Map<String, dynamic>;
  }

  Future<bool> uploadFileToPresignedUrl({
    required String uploadUrl,
    required File file,
    required String contentType,
    required void Function(double)? onProgress,
  }) async {
    final fileLength = await file.length();
    final uploadDio = Dio();
    final response = await uploadDio.put(
      uploadUrl,
      data: file.openRead(),
      options: Options(
        headers: {
          'Content-Type': contentType,
          'Content-Length': fileLength,
        },
        followRedirects: false,
        validateStatus: (s) => s != null && s < 400,
      ),
      onSendProgress: (sent, total) {
        if (total > 0 && onProgress != null) {
          onProgress(sent / total);
        }
      },
    );
    return response.statusCode != null && response.statusCode! < 400;
  }

  // Socket management
  void connectSocket(String token) {
    if (!SocketManager.instance.chatSocket.isConnected) {
      SocketManager.instance.chatSocket.connect(token);
    }
  }

  void subscribeToConversation({
    required String conversationId,
    required void Function(dynamic ack) ackCallback,
  }) {
    SocketManager.instance.chatSocket.emitWithAck(
      SocketEvents.conversationSubscribe,
      {'conversationId': conversationId, 'afterSeq': 0, 'limit': 100},
      ack: ackCallback,
    );
  }

  void unsubscribeFromConversation(String conversationId) {
    SocketManager.instance.chatSocket.emitWithAck(
      SocketEvents.conversationUnsubscribe,
      {'conversationId': conversationId},
      ack: (_) {},
    );
  }

  void listenToMessages(void Function(dynamic data) onMessage) {
    SocketManager.instance.chatSocket.on(SocketEvents.taskMessageNew, onMessage);
  }

  void stopListeningToMessages() {
    SocketManager.instance.chatSocket.off(SocketEvents.taskMessageNew);
  }

  void listenToTyping(void Function(dynamic data) onTyping) {
    SocketManager.instance.chatSocket.on(SocketEvents.typingStart, onTyping);
  }

  void stopListeningToTyping() {
    SocketManager.instance.chatSocket.off(SocketEvents.typingStart);
  }

  void listenToTypingStop(void Function(dynamic data) onTypingStop) {
    SocketManager.instance.chatSocket.on(SocketEvents.typingStop, onTypingStop);
  }

  void stopListeningToTypingStop() {
    SocketManager.instance.chatSocket.off(SocketEvents.typingStop);
  }

  void sendSocketMessage(Map<String, dynamic> data, void Function(dynamic ack) onAck) {
    SocketManager.instance.chatSocket.emitWithAck(
      SocketEvents.taskMessageSend,
      data,
      ack: onAck,
    );
  }

  void emitTypingStart(String conversationId, String myId, String myName) {
    SocketManager.instance.chatSocket.emit(SocketEvents.typingStart, {
      'conversationId': conversationId,
      'actorId': myId,
      'actorName': myName,
    });
  }

  void emitTypingStop(String conversationId, String myId) {
    SocketManager.instance.chatSocket.emit(SocketEvents.typingStop, {
      'conversationId': conversationId,
      'actorId': myId,
    });
  }
}
