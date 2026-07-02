import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/colleague_entity.dart';
import '../../domain/repositories/team_chat_repository.dart';

class ColleaguesState extends Equatable {
  final List<ColleagueEntity> colleagues;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int page;
  final String search;
  final String? errorMessage;

  const ColleaguesState({
    this.colleagues = const [],
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = false,
    this.page = 1,
    this.search = '',
    this.errorMessage,
  });

  ColleaguesState copyWith({
    List<ColleagueEntity>? colleagues,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? page,
    String? search,
    String? errorMessage,
  }) {
    return ColleaguesState(
      colleagues: colleagues ?? this.colleagues,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      page: page ?? this.page,
      search: search ?? this.search,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props =>
      [colleagues, isLoading, isLoadingMore, hasMore, page, search, errorMessage];
}

/// Drives the colleague picker: `GET chat-v2/app/colleagues` with search + paging.
class ColleaguesCubit extends Cubit<ColleaguesState> {
  final TeamChatRepository _repository;
  ColleaguesCubit(this._repository) : super(const ColleaguesState());

  Future<void> load({String search = ''}) async {
    emit(state.copyWith(isLoading: true, search: search, errorMessage: null));
    final (pageData, failure) = await _repository.getColleagues(search: search, page: 1);
    if (failure != null) {
      emit(state.copyWith(isLoading: false, errorMessage: failure.message));
      return;
    }
    emit(state.copyWith(
      isLoading: false,
      colleagues: pageData!.items,
      hasMore: pageData.hasMore,
      page: pageData.page,
    ));
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;
    emit(state.copyWith(isLoadingMore: true));
    final (pageData, failure) =
        await _repository.getColleagues(search: state.search, page: state.page + 1);
    if (failure != null) {
      emit(state.copyWith(isLoadingMore: false, errorMessage: failure.message));
      return;
    }
    emit(state.copyWith(
      isLoadingMore: false,
      colleagues: [...state.colleagues, ...pageData!.items],
      hasMore: pageData.hasMore,
      page: pageData.page,
    ));
  }
}
