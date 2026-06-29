import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/repositories/sos_repository.dart';

// Events
abstract class SosEvent extends Equatable {
  const SosEvent();
  @override
  List<Object?> get props => [];
}

class StartSosEvent extends SosEvent {
  final double lat;
  final double lng;
  const StartSosEvent({required this.lat, required this.lng});
  @override
  List<Object?> get props => [lat, lng];
}

class StopSosEvent extends SosEvent {
  const StopSosEvent();
}

// States
abstract class SosState extends Equatable {
  const SosState();
  @override
  List<Object?> get props => [];
}

class SosInitial extends SosState {
  const SosInitial();
}

class SosLoading extends SosState {
  const SosLoading();
}

class SosStopping extends SosState {
  const SosStopping();
}

class SosActive extends SosState {
  final String message;
  const SosActive([this.message = 'SOS activated. Help is on the way.']);
  @override
  List<Object?> get props => [message];
}

// BLoC
class SosBloc extends Bloc<SosEvent, SosState> {
  final SosRepository _repo;

  SosBloc(this._repo) : super(const SosInitial()) {
    on<StartSosEvent>(_onStartSos);
    on<StopSosEvent>(_onStopSos);
  }

  Future<void> _onStartSos(StartSosEvent event, Emitter<SosState> emit) async {
    emit(const SosLoading());
    await _repo.startSos(lat: event.lat, lng: event.lng);
    emit(const SosActive());
  }

  Future<void> _onStopSos(StopSosEvent event, Emitter<SosState> emit) async {
    emit(const SosStopping());
    await _repo.stopSos();
    emit(const SosInitial());
  }
}
