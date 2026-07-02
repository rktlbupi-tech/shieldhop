import 'dart:io';
import 'package:mime/mime.dart';
import 'package:path/path.dart' as p;
import '../../../../core/errors/failures.dart';
import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/entities/colleague_entity.dart';
import '../../domain/entities/team_chat_message_entity.dart';
import '../../domain/repositories/team_chat_repository.dart';
import '../datasources/team_chat_remote_datasource.dart';
import '../models/chat_conversation_model.dart';
import '../models/colleague_model.dart';
import '../models/team_chat_message_model.dart';

/// Chat modes surfaced in the team-chat list (mirrors the legacy app).
const String _kTeamChatModes =
    'enterprise-task-group,enterprise-task-direct,hopper-direct,hopper-group,enterprise-org-team';

class TeamChatRepositoryImpl implements TeamChatRepository {
  final TeamChatRemoteDataSource _remoteDataSource;
  TeamChatRepositoryImpl(this._remoteDataSource);

  // ── Peer chat — see docs/api/peer-chat.md ──────────────────────────────────

  @override
  Future<(ColleaguesPage?, Failure?)> getColleagues({
    String? search,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _remoteDataSource.getColleagues(
        search: search,
        page: page,
        limit: limit,
      );
      if (response['success'] == true && response['data'] is Map) {
        final inner = Map<String, dynamic>.from(response['data'] as Map);
        return (ColleaguesPageModel.fromJson(inner), null);
      }
      return (null, ServerFailure(response['message']?.toString() ?? 'Failed to load colleagues'));
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<ChatConversationEntity>?, Failure?)> getConversations({
    String? chatMode,
    int limit = 20,
    String? cursor,
  }) async {
    try {
      final response = await _remoteDataSource.getConversations(
        chatMode: chatMode ?? _kTeamChatModes,
        limit: limit,
        cursor: cursor,
      );
      if (response['success'] == true && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final rawItems = data['items'] as List<dynamic>? ?? const [];
        final items = rawItems
            .whereType<Map>()
            .map((e) => ChatConversationModel.fromJson(Map<String, dynamic>.from(e)).toEntity())
            .toList();
        return (items, null);
      }
      return (null, ServerFailure(response['message']?.toString() ?? 'Failed to load conversations'));
    } on NotFoundFailure {
      return (<ChatConversationEntity>[], null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(ChatConversationEntity?, Failure?)> createConversation({
    required String channelType,
    String? title,
    required List<String> memberIds,
    String fallbackTitle = '',
    String fallbackAvatar = '',
  }) async {
    try {
      final response = await _remoteDataSource.createConversation(
        channelType: channelType,
        title: title,
        memberIds: memberIds,
      );
      if (response['success'] == true && response['data'] is Map) {
        final data = Map<String, dynamic>.from(response['data'] as Map);
        final convo = ChatConversationModel.fromCreated(
          data,
          fallbackTitle: fallbackTitle,
          fallbackAvatar: fallbackAvatar,
        ).toEntity();
        if (convo.id.isEmpty) {
          return (null, const ServerFailure('Chat created but no id was returned'));
        }
        return (convo, null);
      }
      return (null, ServerFailure(response['message']?.toString() ?? 'Failed to create chat'));
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<TeamChatMessageEntity>?, Failure?)> getMessages(
    String conversationId, {
    int limit = 50,
  }) async {
    try {
      final response = await _remoteDataSource.getMessages(conversationId, limit: limit);
      if (response['success'] == true && response['data'] != null) {
        final items = (response['data']['items'] as List<dynamic>?) ?? [];
        final messages = items
            .map((e) => TeamChatMessageModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
            .toList();
        return (messages, null);
      }
      return (null, ServerFailure(response['error']?.toString() ?? 'Failed to load messages'));
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<String>?, Failure?)> prepareAndUploadMedia({
    required String conversationId,
    required List<File> files,
    void Function(double)? onProgress,
  }) async {
    try {
      final items = files.map((f) {
        return {
          'fileName': p.basename(f.path),
          'contentType': lookupMimeType(f.path) ?? 'application/octet-stream',
          'size': f.lengthSync(),
        };
      }).toList();

      final prepareResp = await _remoteDataSource.prepareMedia(conversationId, items);
      if (prepareResp['success'] == false) {
        return (null, ServerFailure(prepareResp['error']?.toString() ?? 'Failed to prepare media'));
      }

      final raw = prepareResp['data'] ?? prepareResp;
      final list = raw is List ? raw : (raw['items'] as List);
      final List<String> assetIds = [];

      for (int i = 0; i < list.length; i++) {
        final asset = list[i] as Map<String, dynamic>;
        final uploadUrl = asset['uploadUrl'] as String;
        final assetId = asset['assetId'] as String;
        final file = files[i];
        final contentType = lookupMimeType(file.path) ?? 'application/octet-stream';

        final uploadSuccess = await _remoteDataSource.uploadFileToPresignedUrl(
          uploadUrl: uploadUrl,
          file: file,
          contentType: contentType,
          onProgress: (progress) {
            if (onProgress != null) {
              onProgress((i + progress) / list.length);
            }
          },
        );

        if (uploadSuccess) {
          assetIds.add(assetId);
        }
      }

      if (assetIds.isEmpty) {
        return (null, ServerFailure('Failed to upload files'));
      }
      return (assetIds, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  void connectSocket(String token) {
    _remoteDataSource.connectSocket(token);
  }

  @override
  void subscribeToConversation(
    String conversationId, {
    required void Function(List<TeamChatMessageEntity> messages) onMessagesSynced,
  }) {
    _remoteDataSource.subscribeToConversation(
      conversationId: conversationId,
      ackCallback: (ack) {
        if (ack != null && ack['success'] == true && ack['data'] != null) {
          final items = (ack['data']['items'] as List<dynamic>?) ?? [];
          final messages = items
              .map((e) => TeamChatMessageModel.fromJson(Map<String, dynamic>.from(e as Map)).toEntity())
              .toList();
          onMessagesSynced(messages);
        }
      },
    );
  }

  @override
  void unsubscribeFromConversation(String conversationId) {
    _remoteDataSource.unsubscribeFromConversation(conversationId);
  }

  @override
  void listenToMessages({
    required void Function(TeamChatMessageEntity message) onNewMessage,
  }) {
    _remoteDataSource.listenToMessages((data) {
      if (data is Map) {
        final model = TeamChatMessageModel.fromJson(Map<String, dynamic>.from(data));
        onNewMessage(model.toEntity());
      }
    });
  }

  @override
  void stopListeningToMessages() {
    _remoteDataSource.stopListeningToMessages();
  }

  @override
  void listenToTyping({
    required void Function(String actorId, String userName) onTypingStart,
    required void Function(String actorId) onTypingStop,
  }) {
    _remoteDataSource.listenToTyping((data) {
      if (data is Map) {
        final actorId = data['actorId']?.toString() ?? data['userId']?.toString() ?? '';
        final actorName = data['actorName']?.toString() ?? data['userName']?.toString() ?? '';
        if (actorId.isNotEmpty) {
          onTypingStart(actorId, actorName);
        }
      }
    });

    _remoteDataSource.listenToTypingStop((data) {
      if (data is Map) {
        final actorId = data['actorId']?.toString() ?? data['userId']?.toString() ?? '';
        if (actorId.isNotEmpty) {
          onTypingStop(actorId);
        }
      }
    });
  }

  @override
  void stopListeningToTyping() {
    _remoteDataSource.stopListeningToTyping();
    _remoteDataSource.stopListeningToTypingStop();
  }

  @override
  void sendMessage({
    required String conversationId,
    required String text,
    List<String>? mediaAssetIds,
    required void Function(bool success, String? error) onResult,
  }) {
    final payload = {
      'conversationId': conversationId,
      'clientMessageId': 'msg-${DateTime.now().millisecondsSinceEpoch}',
      'kind': mediaAssetIds != null && mediaAssetIds.isNotEmpty ? 'media' : 'text',
      'payload': {'text': text},
    };

    if (mediaAssetIds != null && mediaAssetIds.isNotEmpty) {
      payload['mediaAssetIds'] = mediaAssetIds;
    }

    _remoteDataSource.sendSocketMessage(payload, (ack) {
      if (ack != null && ack['success'] == false) {
        onResult(false, ack['error']?.toString() ?? 'Failed to send message');
      } else {
        onResult(ack != null, null);
      }
    });
  }

  @override
  void emitTypingStart(String conversationId, String myId, String myName) {
    _remoteDataSource.emitTypingStart(conversationId, myId, myName);
  }

  @override
  void emitTypingStop(String conversationId, String myId) {
    _remoteDataSource.emitTypingStop(conversationId, myId);
  }
}
