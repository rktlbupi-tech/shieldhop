import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';

abstract class HomeEvent extends Equatable {
  const HomeEvent();
  @override
  List<Object?> get props => [];
}

class FetchHome extends HomeEvent {
  const FetchHome();
}

abstract class HomeState extends Equatable {
  const HomeState();
  @override
  List<Object?> get props => [];
}

class HomeInitial extends HomeState {
  const HomeInitial();
}

class HomeLoading extends HomeState {
  const HomeLoading();
}

class HomeLoaded extends HomeState {
  final HomeData data;
  const HomeLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class HomeError extends HomeState {
  final String message;
  const HomeError(this.message);
  @override
  List<Object?> get props => [message];
}

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  final HomeRepository _repo;
  HomeBloc(this._repo) : super(const HomeInitial()) {
    on<FetchHome>(_onFetch);
  }

  Future<void> _onFetch(FetchHome e, Emitter<HomeState> emit) async {
    emit(const HomeLoading());
    final (data, failure) = await _repo.fetchHome();
    if (failure != null || data == null) {
      emit(HomeError(failure?.message ?? 'Unable to load home.'));
      return;
    }
    emit(HomeLoaded(data));
  }
}
