import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/mileage_entities.dart';
import '../../domain/repositories/mileage_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class MileageEvent extends Equatable {
  const MileageEvent();
  @override
  List<Object?> get props => [];
}

/// Loads the screen: KPI summary + day-wise trips for [period] ending at [date].
class FetchMileageOverview extends MileageEvent {
  final MileagePeriod period;
  final String? date; // YYYY-MM-DD
  const FetchMileageOverview({
    this.period = MileagePeriod.monthly,
    this.date,
  });
  @override
  List<Object?> get props => [period, date];
}

/// Logs (or replaces) a day's travel, then refreshes.
class LogMileageDay extends MileageEvent {
  final String? date;
  final double? distanceMeters;
  final double? odometerStart;
  final double? odometerEnd;
  final int? durationMinutes;
  final String? startLabel;
  final String? endLabel;
  const LogMileageDay({
    this.date,
    this.distanceMeters,
    this.odometerStart,
    this.odometerEnd,
    this.durationMinutes,
    this.startLabel,
    this.endLabel,
  });
  @override
  List<Object?> get props =>
      [date, distanceMeters, odometerStart, odometerEnd, durationMinutes];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class MileageState extends Equatable {
  const MileageState();
  @override
  List<Object?> get props => [];
}

class MileageInitial extends MileageState {
  const MileageInitial();
}

class MileageLoading extends MileageState {
  const MileageLoading();
}

class MileageLoaded extends MileageState {
  final MileageSummaryEntity? summary;
  final List<MileageTripEntity> trips;
  final MileagePeriod period;
  final String? date;
  final bool isSubmitting;

  const MileageLoaded({
    this.summary,
    this.trips = const [],
    this.period = MileagePeriod.monthly,
    this.date,
    this.isSubmitting = false,
  });

  MileageLoaded copyWith({
    MileageSummaryEntity? summary,
    List<MileageTripEntity>? trips,
    MileagePeriod? period,
    String? date,
    bool? isSubmitting,
  }) {
    return MileageLoaded(
      summary: summary ?? this.summary,
      trips: trips ?? this.trips,
      period: period ?? this.period,
      date: date ?? this.date,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [summary, trips, period, date, isSubmitting];
}

class LogMileageSuccess extends MileageLoaded {
  const LogMileageSuccess({
    super.summary,
    super.trips,
    super.period,
    super.date,
  });
  @override
  List<Object?> get props => [...super.props, 'logged'];
}

class LogMileageFailure extends MileageLoaded {
  final String errorMessage;
  const LogMileageFailure(
    this.errorMessage, {
    super.summary,
    super.trips,
    super.period,
    super.date,
  });
  @override
  List<Object?> get props => [...super.props, errorMessage];
}

class MileageError extends MileageState {
  final String message;
  const MileageError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class MileageBloc extends Bloc<MileageEvent, MileageState> {
  final MileageRepository _repo;

  MileageSummaryEntity? _summary;
  List<MileageTripEntity> _trips = const [];
  MileagePeriod _period = MileagePeriod.monthly;
  String? _date;

  MileageBloc(this._repo) : super(const MileageInitial()) {
    on<FetchMileageOverview>(_onFetch);
    on<LogMileageDay>(_onLog);
  }

  MileageLoaded get _loaded => MileageLoaded(
        summary: _summary,
        trips: _trips,
        period: _period,
        date: _date,
      );

  Future<void> _onFetch(
    FetchMileageOverview e,
    Emitter<MileageState> emit,
  ) async {
    emit(const MileageLoading());
    _period = e.period;
    _date = e.date;

    final results = await Future.wait([
      _repo.fetchSummary(period: e.period, date: e.date),
      _repo.fetchTrips(period: e.period, date: e.date),
    ]);

    final (summary, summaryErr) = results[0] as (MileageSummaryEntity?, dynamic);
    final (trips, tripsErr) = results[1] as (List<MileageTripEntity>, dynamic);

    if (summaryErr != null && tripsErr != null && trips.isEmpty) {
      emit(MileageError(
          (summaryErr.message as String?) ?? 'Unable to load mileage.'));
      return;
    }

    _summary = summary;
    _trips = trips;
    emit(_loaded);
  }

  Future<void> _onLog(LogMileageDay e, Emitter<MileageState> emit) async {
    emit(_loaded.copyWith(isSubmitting: true));

    final (trip, err) = await _repo.logDay(
      date: e.date,
      distanceMeters: e.distanceMeters,
      odometerStart: e.odometerStart,
      odometerEnd: e.odometerEnd,
      durationMinutes: e.durationMinutes,
      startLabel: e.startLabel,
      endLabel: e.endLabel,
    );

    if (trip != null) {
      // Refresh so KPI deltas + the day list reflect the new/replaced record.
      final results = await Future.wait([
        _repo.fetchSummary(period: _period, date: _date),
        _repo.fetchTrips(period: _period, date: _date),
      ]);
      final (summary, _) = results[0] as (MileageSummaryEntity?, dynamic);
      final (trips, _) = results[1] as (List<MileageTripEntity>, dynamic);
      if (summary != null) _summary = summary;
      _trips = trips;
      emit(LogMileageSuccess(
        summary: _summary,
        trips: _trips,
        period: _period,
        date: _date,
      ));
      emit(_loaded);
    } else {
      emit(LogMileageFailure(
        err?.message ?? 'Unable to log mileage.',
        summary: _summary,
        trips: _trips,
        period: _period,
        date: _date,
      ));
      emit(_loaded);
    }
  }
}
