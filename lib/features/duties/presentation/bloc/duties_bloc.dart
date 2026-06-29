import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/duty_entities.dart';
import '../../domain/repositories/duties_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class DutiesEvent extends Equatable {
  const DutiesEvent();
  @override
  List<Object?> get props => [];
}

/// Loads the main Duties screen: current duty + upcoming + today's tasks.
class FetchDutiesOverview extends DutiesEvent {
  const FetchDutiesOverview();
}

/// Loads the Duties history screen for a given range.
class FetchDutyHistory extends DutiesEvent {
  final DutyHistoryRange range;
  const FetchDutyHistory({this.range = DutyHistoryRange.lastYear});
  @override
  List<Object?> get props => [range];
}

/// Submits a handover issue report.
class SubmitHandoverReport extends DutiesEvent {
  final String siteName;
  final String details;
  const SubmitHandoverReport({required this.siteName, required this.details});
  @override
  List<Object?> get props => [siteName, details];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class DutiesState extends Equatable {
  const DutiesState();
  @override
  List<Object?> get props => [];
}

class DutiesInitial extends DutiesState {
  const DutiesInitial();
}

class DutiesLoading extends DutiesState {
  const DutiesLoading();
}

class DutiesOverviewLoaded extends DutiesState {
  final DutyCurrentEntity? current;
  final List<UpcomingShiftEntity> upcoming;
  final List<TodayTaskEntity> todayTasks;
  final bool isSubmittingHandover;

  const DutiesOverviewLoaded({
    this.current,
    this.upcoming = const [],
    this.todayTasks = const [],
    this.isSubmittingHandover = false,
  });

  DutiesOverviewLoaded copyWith({
    DutyCurrentEntity? current,
    List<UpcomingShiftEntity>? upcoming,
    List<TodayTaskEntity>? todayTasks,
    bool? isSubmittingHandover,
  }) {
    return DutiesOverviewLoaded(
      current: current ?? this.current,
      upcoming: upcoming ?? this.upcoming,
      todayTasks: todayTasks ?? this.todayTasks,
      isSubmittingHandover: isSubmittingHandover ?? this.isSubmittingHandover,
    );
  }

  @override
  List<Object?> get props =>
      [current, upcoming, todayTasks, isSubmittingHandover];
}

/// Emitted once after a successful handover report. Extends the loaded state so
/// the screen keeps rendering while a listener shows a confirmation.
class HandoverSubmitSuccess extends DutiesOverviewLoaded {
  final HandoverReportEntity report;
  const HandoverSubmitSuccess(
    this.report, {
    super.current,
    super.upcoming,
    super.todayTasks,
  });
  @override
  List<Object?> get props => [...super.props, report];
}

class HandoverSubmitFailure extends DutiesOverviewLoaded {
  final String errorMessage;
  const HandoverSubmitFailure(
    this.errorMessage, {
    super.current,
    super.upcoming,
    super.todayTasks,
  });
  @override
  List<Object?> get props => [...super.props, errorMessage];
}

class DutiesError extends DutiesState {
  final String message;
  const DutiesError(this.message);
  @override
  List<Object?> get props => [message];
}

// History (own screen / own bloc instance).
class DutiesHistoryLoading extends DutiesState {
  const DutiesHistoryLoading();
}

class DutiesHistoryLoaded extends DutiesState {
  final DutyHistoryEntity history;
  final DutyHistoryRange range;
  const DutiesHistoryLoaded(this.history, this.range);
  @override
  List<Object?> get props => [history, range];
}

class DutiesHistoryError extends DutiesState {
  final String message;
  const DutiesHistoryError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class DutiesBloc extends Bloc<DutiesEvent, DutiesState> {
  final DutiesRepository _repo;

  // Cached overview data so handover-submit emissions don't blank the screen.
  DutyCurrentEntity? _current;
  List<UpcomingShiftEntity> _upcoming = const [];
  List<TodayTaskEntity> _todayTasks = const [];

  DutiesBloc(this._repo) : super(const DutiesInitial()) {
    on<FetchDutiesOverview>(_onFetchOverview);
    on<FetchDutyHistory>(_onFetchHistory);
    on<SubmitHandoverReport>(_onSubmitHandover);
  }

  DutiesOverviewLoaded get _overview => DutiesOverviewLoaded(
        current: _current,
        upcoming: _upcoming,
        todayTasks: _todayTasks,
      );

  Future<void> _onFetchOverview(
    FetchDutiesOverview e,
    Emitter<DutiesState> emit,
  ) async {
    emit(const DutiesLoading());

    final results = await Future.wait([
      _repo.fetchCurrent(),
      _repo.fetchUpcoming(),
      _repo.fetchTodayTasks(),
    ]);

    final (current, currentErr) = results[0] as (DutyCurrentEntity?, dynamic);
    final (upcoming, _) = results[1] as (List<UpcomingShiftEntity>, dynamic);
    final (todayTasks, _) = results[2] as (List<TodayTaskEntity>, dynamic);

    // Current is the primary payload; only fail hard if it errored and we got
    // nothing back. Upcoming / today-tasks degrade to empty lists.
    if (currentErr != null && current == null) {
      emit(DutiesError(
          (currentErr.message as String?) ?? 'Unable to load duties.'));
      return;
    }

    _current = current;
    _upcoming = upcoming;
    _todayTasks = todayTasks;
    emit(_overview);
  }

  Future<void> _onFetchHistory(
    FetchDutyHistory e,
    Emitter<DutiesState> emit,
  ) async {
    emit(const DutiesHistoryLoading());
    final (history, err) = await _repo.fetchHistory(range: e.range);
    if (err != null && history == null) {
      emit(DutiesHistoryError(err.message));
      return;
    }
    emit(DutiesHistoryLoaded(
        history ?? const DutyHistoryEntity(), e.range));
  }

  Future<void> _onSubmitHandover(
    SubmitHandoverReport e,
    Emitter<DutiesState> emit,
  ) async {
    emit(_overview.copyWith(isSubmittingHandover: true));

    final (report, err) = await _repo.submitHandoverReport(
      siteName: e.siteName,
      details: e.details,
    );

    if (report != null) {
      emit(HandoverSubmitSuccess(
        report,
        current: _current,
        upcoming: _upcoming,
        todayTasks: _todayTasks,
      ));
      emit(_overview);
    } else {
      emit(HandoverSubmitFailure(
        err?.message ?? 'Unable to submit report.',
        current: _current,
        upcoming: _upcoming,
        todayTasks: _todayTasks,
      ));
      emit(_overview);
    }
  }
}
