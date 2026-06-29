import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/earning_entity.dart';
import '../../domain/repositories/earnings_repository.dart';

abstract class EarningsEvent extends Equatable {
  const EarningsEvent();
  @override
  List<Object?> get props => [];
}

class FetchEarnings extends EarningsEvent {
  final int? year;
  const FetchEarnings({this.year});
  @override
  List<Object?> get props => [year];
}

abstract class EarningsState extends Equatable {
  const EarningsState();
  @override
  List<Object?> get props => [];
}

class EarningsInitial extends EarningsState {
  const EarningsInitial();
}

class EarningsLoading extends EarningsState {
  const EarningsLoading();
}

class EarningsLoaded extends EarningsState {
  final YearlyEarningsEntity data;
  const EarningsLoaded(this.data);
  @override
  List<Object?> get props => [data];
}

class EarningsError extends EarningsState {
  final String message;
  const EarningsError(this.message);
  @override
  List<Object?> get props => [message];
}

class EarningsBloc extends Bloc<EarningsEvent, EarningsState> {
  final EarningsRepository _repo;
  EarningsBloc(this._repo) : super(const EarningsInitial()) {
    on<FetchEarnings>(_onFetch);
  }

  Future<void> _onFetch(FetchEarnings e, Emitter<EarningsState> emit) async {
    emit(const EarningsLoading());
    final (data, failure) = await _repo.fetchEarnings(year: e.year);
    if (failure != null && data == null) {
      emit(EarningsError(failure.message));
      return;
    }
    emit(EarningsLoaded(
        data ?? YearlyEarningsEntity(year: e.year ?? DateTime.now().year)));
  }
}
