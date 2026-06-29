import 'dart:async';
import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/team_chat_message_entity.dart';
import '../../domain/repositories/team_chat_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class TeamChatEvent extends Equatable {
  const TeamChatEvent();
  @override
  List<Object?> get props => [];
}

class InitTeamChatEvent extends TeamChatEvent {
  final String conversationId;
  final String token;
  const InitTeamChatEvent({required this.conversationId, required this.token});
  @override
  List<Object?> get props => [conversationId, token];
}

class SyncTeamChatMessagesEvent extends TeamChatEvent {
  final List<TeamChatMessageEntity> messages;
  const SyncTeamChatMessagesEvent(this.messages);
  @override
  List<Object?> get props => [messages];
}

class ReceiveTeamChatMessageEvent extends TeamChatEvent {
  final TeamChatMessageEntity message;
  const ReceiveTeamChatMessageEvent(this.message);
  @override
  List<Object?> get props => [message];
}

class ReceiveTeamChatTypingEvent extends TeamChatEvent {
  final String actorId;
  final String actorName;
  const ReceiveTeamChatTypingEvent({required this.actorId, required this.actorName});
  @override
  List<Object?> get props => [actorId, actorName];
}

class ReceiveTeamChatTypingStopEvent extends TeamChatEvent {
  final String actorId;
  const ReceiveTeamChatTypingStopEvent({required this.actorId});
  @override
  List<Object?> get props => [actorId];
}

class SendTeamChatMessageEvent extends TeamChatEvent {
  final String text;
  final String myId;
  final String myName;
  const SendTeamChatMessageEvent({required this.text, required this.myId, required this.myName});
  @override
  List<Object?> get props => [text, myId, myName];
}

class SendTeamChatMediaEvent extends TeamChatEvent {
  final List<File> files;
  const SendTeamChatMediaEvent({required this.files});
  @override
  List<Object?> get props => [files];
}

class SendTeamChatTypingInputEvent extends TeamChatEvent {
  final String myId;
  final String myName;
  const SendTeamChatTypingInputEvent({required this.myId, required this.myName});
  @override
  List<Object?> get props => [myId, myName];
}

class ClearTeamChatErrorEvent extends TeamChatEvent {
  const ClearTeamChatErrorEvent();
}

// ── States ───────────────────────────────────────────────────────────────────
class TeamChatState extends Equatable {
  final List<TeamChatMessageEntity> messages;
  final bool isLoading;
  final bool isUploading;
  final String? errorMessage;
  final Map<String, String> typingMembers; // actorId -> actorName

  const TeamChatState({
    this.messages = const [],
    this.isLoading = false,
    this.isUploading = false,
    this.errorMessage,
    this.typingMembers = const {},
  });

  TeamChatState copyWith({
    List<TeamChatMessageEntity>? messages,
    bool? isLoading,
    bool? isUploading,
    String? errorMessage,
    Map<String, String>? typingMembers,
  }) {
    return TeamChatState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isUploading: isUploading ?? this.isUploading,
      errorMessage: errorMessage,
      typingMembers: typingMembers ?? this.typingMembers,
    );
  }

  @override
  List<Object?> get props => [messages, isLoading, isUploading, errorMessage, typingMembers];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class TeamChatBloc extends Bloc<TeamChatEvent, TeamChatState> {
  final TeamChatRepository _repository;
  String? _conversationId;
  Timer? _typingDebounce;
  final Map<String, Timer> _typerTimers = {};

  TeamChatBloc(this._repository) : super(const TeamChatState()) {
    on<InitTeamChatEvent>(_onInit);
    on<SyncTeamChatMessagesEvent>(_onSyncMessages);
    on<ReceiveTeamChatMessageEvent>(_onReceiveMessage);
    on<ReceiveTeamChatTypingEvent>(_onReceiveTyping);
    on<ReceiveTeamChatTypingStopEvent>(_onReceiveTypingStop);
    on<SendTeamChatMessageEvent>(_onSendMessage);
    on<SendTeamChatMediaEvent>(_onSendMedia);
    on<SendTeamChatTypingInputEvent>(_onTypingInput);
    on<ClearTeamChatErrorEvent>((e, emit) => emit(state.copyWith(errorMessage: null)));
  }

  Future<void> _onInit(InitTeamChatEvent event, Emitter<TeamChatState> emit) async {
    _conversationId = event.conversationId;
    emit(state.copyWith(isLoading: true));

    // Connect socket
    _repository.connectSocket(event.token);

    // Fetch message history from REST API
    final (history, failure) = await _repository.getMessages(event.conversationId);
    if (failure != null) {
      emit(state.copyWith(
        isLoading: false,
        errorMessage: failure.message,
      ));
    } else if (history != null) {
      emit(state.copyWith(
        isLoading: false,
        messages: _sortMessages(history),
      ));
    }

    // Subscribe to socket room
    _repository.subscribeToConversation(
      event.conversationId,
      onMessagesSynced: (syncedMessages) {
        add(SyncTeamChatMessagesEvent(syncedMessages));
      },
    );

    // Listen to new messages
    _repository.listenToMessages(
      onNewMessage: (msg) {
        add(ReceiveTeamChatMessageEvent(msg));
      },
    );

    // Listen to typing status
    _repository.listenToTyping(
      onTypingStart: (actorId, name) {
        add(ReceiveTeamChatTypingEvent(actorId: actorId, actorName: name));
      },
      onTypingStop: (actorId) {
        add(ReceiveTeamChatTypingStopEvent(actorId: actorId));
      },
    );
  }

  void _onSyncMessages(SyncTeamChatMessagesEvent event, Emitter<TeamChatState> emit) {
    final currentList = List<TeamChatMessageEntity>.from(state.messages);
    for (final msg in event.messages) {
      _addMessageUniquely(currentList, msg);
    }
    emit(state.copyWith(messages: _sortMessages(currentList)));
  }

  void _onReceiveMessage(ReceiveTeamChatMessageEvent event, Emitter<TeamChatState> emit) {
    final currentList = List<TeamChatMessageEntity>.from(state.messages);
    _addMessageUniquely(currentList, event.message);
    emit(state.copyWith(messages: _sortMessages(currentList)));
  }

  void _onReceiveTyping(ReceiveTeamChatTypingEvent event, Emitter<TeamChatState> emit) {
    final updatedTypers = Map<String, String>.from(state.typingMembers);
    updatedTypers[event.actorId] = event.actorName;

    // Reset previous timer for this typer if it exists
    _typerTimers[event.actorId]?.cancel();
    _typerTimers[event.actorId] = Timer(const Duration(seconds: 3), () {
      add(ReceiveTeamChatTypingStopEvent(actorId: event.actorId));
    });

    emit(state.copyWith(typingMembers: updatedTypers));
  }

  void _onReceiveTypingStop(ReceiveTeamChatTypingStopEvent event, Emitter<TeamChatState> emit) {
    final updatedTypers = Map<String, String>.from(state.typingMembers);
    updatedTypers.remove(event.actorId);
    _typerTimers[event.actorId]?.cancel();
    _typerTimers.remove(event.actorId);
    emit(state.copyWith(typingMembers: updatedTypers));
  }

  void _onSendMessage(SendTeamChatMessageEvent event, Emitter<TeamChatState> emit) {
    if (_conversationId == null) return;

    // Optimistically insert local message
    final optimisticMsg = TeamChatMessageEntity(
      id: 'optimistic-${DateTime.now().millisecondsSinceEpoch}',
      clientMessageId: 'optimistic-${DateTime.now().millisecondsSinceEpoch}',
      senderId: event.myId,
      senderName: event.myName,
      senderProfileImage: '',
      text: event.text,
      kind: 'text',
      createdAt: DateTime.now(),
    );

    final currentList = List<TeamChatMessageEntity>.from(state.messages);
    _addMessageUniquely(currentList, optimisticMsg);

    emit(state.copyWith(messages: _sortMessages(currentList)));

    // Emit send-message via socket
    _repository.sendMessage(
      conversationId: _conversationId!,
      text: event.text,
      onResult: (success, error) {
        if (!success) {
          add(ClearTeamChatErrorEvent()); // clear error
          emit(state.copyWith(errorMessage: error ?? 'Failed to send message'));
        }
      },
    );
  }

  Future<void> _onSendMedia(SendTeamChatMediaEvent event, Emitter<TeamChatState> emit) async {
    if (_conversationId == null) return;
    emit(state.copyWith(isUploading: true));

    final (assetIds, failure) = await _repository.prepareAndUploadMedia(
      conversationId: _conversationId!,
      files: event.files,
    );

    if (failure != null) {
      emit(state.copyWith(
        isUploading: false,
        errorMessage: failure.message,
      ));
      return;
    }

    if (assetIds != null && assetIds.isNotEmpty) {
      // Emit media message via socket
      _repository.sendMessage(
        conversationId: _conversationId!,
        text: '',
        mediaAssetIds: assetIds,
        onResult: (success, error) {
          if (!success) {
            emit(state.copyWith(errorMessage: error ?? 'Failed to send media'));
          }
        },
      );
    }

    emit(state.copyWith(isUploading: false));
  }

  void _onTypingInput(SendTeamChatTypingInputEvent event, Emitter<TeamChatState> emit) {
    if (_conversationId == null) return;

    _repository.emitTypingStart(_conversationId!, event.myId, event.myName);

    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      if (_conversationId != null) {
        _repository.emitTypingStop(_conversationId!, event.myId);
      }
    });
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────
  List<TeamChatMessageEntity> _sortMessages(List<TeamChatMessageEntity> list) {
    final sorted = List<TeamChatMessageEntity>.from(list);
    sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return sorted;
  }

  void _addMessageUniquely(List<TeamChatMessageEntity> list, TeamChatMessageEntity newMsg) {
    final String msgId = newMsg.id;

    // Check by id or clientMessageId
    final int idx = list.indexWhere((m) {
      if (m.id == msgId || (m.clientMessageId != null && m.clientMessageId == newMsg.clientMessageId)) {
        return true;
      }
      if (m.clientMessageId != null && m.clientMessageId!.startsWith('optimistic-')) {
        if (m.text == newMsg.text && m.senderId == newMsg.senderId) {
          return true;
        }
      }
      return false;
    });

    if (idx == -1) {
      list.add(newMsg);
    } else {
      list[idx] = newMsg;
    }
  }

  @override
  Future<void> close() {
    _typingDebounce?.cancel();
    for (final timer in _typerTimers.values) {
      timer.cancel();
    }
    _typerTimers.clear();

    if (_conversationId != null) {
      _repository.unsubscribeFromConversation(_conversationId!);
      _repository.stopListeningToMessages();
      _repository.stopListeningToTyping();
    }
    return super.close();
  }
}
