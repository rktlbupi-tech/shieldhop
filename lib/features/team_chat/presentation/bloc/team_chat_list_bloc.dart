import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/chat_conversation_entity.dart';
import '../../domain/repositories/team_chat_repository.dart';

// ── Events ───────────────────────────────────────────────────────────────────
abstract class TeamChatListEvent extends Equatable {
  const TeamChatListEvent();
  @override
  List<Object?> get props => [];
}

class LoadConversationsEvent extends TeamChatListEvent {
  const LoadConversationsEvent();
}

class RefreshConversationsEvent extends TeamChatListEvent {
  const RefreshConversationsEvent();
}

class CreateConversationEvent extends TeamChatListEvent {
  final String channelType; // 'direct' | 'group'
  final String? title;
  final List<String> memberIds;
  final String fallbackTitle;
  final String fallbackAvatar;

  const CreateConversationEvent({
    required this.channelType,
    this.title,
    required this.memberIds,
    this.fallbackTitle = '',
    this.fallbackAvatar = '',
  });

  @override
  List<Object?> get props => [
    channelType,
    title,
    memberIds,
    fallbackTitle,
    fallbackAvatar,
  ];
}

// ── State ────────────────────────────────────────────────────────────────────
class TeamChatListState extends Equatable {
  final List<ChatConversationEntity> conversations;
  final bool isLoading;
  final bool isCreating;
  final String? errorMessage;

  /// One-shot: set when a create just succeeded so the screen navigates once.
  final ChatConversationEntity? createdConversation;

  const TeamChatListState({
    this.conversations = const [],
    this.isLoading = false,
    this.isCreating = false,
    this.errorMessage,
    this.createdConversation,
  });

  List<ChatConversationEntity> get orgTeamChats =>
      conversations.where((c) => c.isOrgTeam).toList();

  List<ChatConversationEntity> get groupChats =>
      conversations.where((c) => !c.isOrgTeam && c.isGroup).toList();

  List<ChatConversationEntity> get directChats =>
      conversations.where((c) => !c.isOrgTeam && !c.isGroup).toList();

  TeamChatListState copyWith({
    List<ChatConversationEntity>? conversations,
    bool? isLoading,
    bool? isCreating,
    String? errorMessage,
    ChatConversationEntity? createdConversation,
  }) {
    return TeamChatListState(
      conversations: conversations ?? this.conversations,
      isLoading: isLoading ?? this.isLoading,
      isCreating: isCreating ?? this.isCreating,
      errorMessage: errorMessage,
      createdConversation: createdConversation,
    );
  }

  @override
  List<Object?> get props => [
    conversations,
    isLoading,
    isCreating,
    errorMessage,
    createdConversation,
  ];
}

// ── BLoC ─────────────────────────────────────────────────────────────────────
class TeamChatListBloc extends Bloc<TeamChatListEvent, TeamChatListState> {
  final TeamChatRepository _repository;

  TeamChatListBloc(this._repository) : super(const TeamChatListState()) {
    on<LoadConversationsEvent>(_onLoad);
    on<RefreshConversationsEvent>(_onRefresh);
    on<CreateConversationEvent>(_onCreate);
  }

  Future<void> _onLoad(
    LoadConversationsEvent event,
    Emitter<TeamChatListState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: null));
    await _fetch(emit);
  }

  Future<void> _onRefresh(
    RefreshConversationsEvent event,
    Emitter<TeamChatListState> emit,
  ) async {
    await _fetch(emit);
  }

  Future<void> _fetch(Emitter<TeamChatListState> emit) async {
    final (items, failure) = await _repository.getConversations();
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
    } else {
      emit(state.copyWith(isLoading: false, conversations: items ?? const []));
    }
  }

  Future<void> _onCreate(
    CreateConversationEvent event,
    Emitter<TeamChatListState> emit,
  ) async {
    emit(state.copyWith(isCreating: true, errorMessage: null));
    final (convo, failure) = await _repository.createConversation(
      channelType: event.channelType,
      title: event.title,
      memberIds: event.memberIds,
      fallbackTitle: event.fallbackTitle,
      fallbackAvatar: event.fallbackAvatar,
    );
    if (failure != null || convo == null) {
      emit(
        state.copyWith(
          isCreating: false,
          errorMessage: failure?.message ?? 'Failed to create chat',
        ),
      );
      return;
    }
    emit(state.copyWith(isCreating: false, createdConversation: convo));
    // Refresh the list so the new chat appears once we come back.
    await _fetch(emit);
  }
}
