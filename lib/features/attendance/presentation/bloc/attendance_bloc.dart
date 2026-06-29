import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/attendance_entity.dart';
import '../../domain/repositories/attendance_repository.dart';

// Events
abstract class AttendanceEvent extends Equatable {
  const AttendanceEvent();
  @override
  List<Object?> get props => [];
}

/// Loads the whole screen: stat cards (summary), log list, and issues.
class FetchAttendanceLog extends AttendanceEvent {
  const FetchAttendanceLog();
}

/// Refreshes just the issues list (after raising one).
class FetchIssues extends AttendanceEvent {
  const FetchIssues();
}

/// Raises an attendance issue. [type] is the API value (e.g. missing_clock_out),
/// [date] is YYYY-MM-DD (or null for today).
class RaiseIssue extends AttendanceEvent {
  final String type;
  final String? date;
  final String details;
  const RaiseIssue({required this.type, this.date, required this.details});
  @override
  List<Object?> get props => [type, date, details];
}

class CheckInRequested extends AttendanceEvent {
  final double lat, lng;
  final double? accuracyMeters;

  /// The uniform selfie to upload before clocking in (optional — required only
  /// when the org enforces a photo on clock-in).
  final File? photoFile;

  const CheckInRequested(
    this.lat,
    this.lng, {
    this.accuracyMeters,
    this.photoFile,
  });
  @override
  List<Object?> get props => [lat, lng, accuracyMeters, photoFile];
}

class CheckOutRequested extends AttendanceEvent {
  final double lat, lng;
  const CheckOutRequested(this.lat, this.lng);
  @override
  List<Object?> get props => [lat, lng];
}

// States
abstract class AttendanceState extends Equatable {
  const AttendanceState();
  @override
  List<Object?> get props => [];
}

class AttendanceInitial extends AttendanceState {
  const AttendanceInitial();
}

class AttendanceLoading extends AttendanceState {
  const AttendanceLoading();
}

class AttendanceLoaded extends AttendanceState {
  final List<AttendanceLogEntity> logs;
  final AttendanceSummaryEntity? summary;
  final List<AttendanceIssueEntity> issues;
  final bool isCheckedIn;

  /// True while a `RaiseIssue` request is in flight (drives the submit spinner).
  final bool isSubmittingIssue;

  const AttendanceLoaded({
    required this.logs,
    this.summary,
    this.issues = const [],
    this.isCheckedIn = false,
    this.isSubmittingIssue = false,
  });

  AttendanceLoaded copyWith({
    List<AttendanceLogEntity>? logs,
    AttendanceSummaryEntity? summary,
    List<AttendanceIssueEntity>? issues,
    bool? isCheckedIn,
    bool? isSubmittingIssue,
  }) {
    return AttendanceLoaded(
      logs: logs ?? this.logs,
      summary: summary ?? this.summary,
      issues: issues ?? this.issues,
      isCheckedIn: isCheckedIn ?? this.isCheckedIn,
      isSubmittingIssue: isSubmittingIssue ?? this.isSubmittingIssue,
    );
  }

  @override
  List<Object?> get props => [
    logs,
    summary,
    issues,
    isCheckedIn,
    isSubmittingIssue,
  ];
}

/// Emitted once after a successful `RaiseIssue`. Extends [AttendanceLoaded] so
/// the screen keeps rendering its data while a listener shows a snackbar.
class AttendanceIssueSubmitSuccess extends AttendanceLoaded {
  final AttendanceIssueEntity issue;
  const AttendanceIssueSubmitSuccess(
    this.issue, {
    required super.logs,
    super.summary,
    super.issues,
    super.isCheckedIn,
  });
  @override
  List<Object?> get props => [...super.props, issue];
}

/// Emitted once after a failed `RaiseIssue`. Extends [AttendanceLoaded] so the
/// list stays on screen while a listener shows the error.
class AttendanceIssueSubmitFailure extends AttendanceLoaded {
  final String errorMessage;
  const AttendanceIssueSubmitFailure(
    this.errorMessage, {
    required super.logs,
    super.summary,
    super.issues,
    super.isCheckedIn,
  });
  @override
  List<Object?> get props => [...super.props, errorMessage];
}

class AttendanceActionSuccess extends AttendanceState {
  final String message;
  final bool isCheckedIn;
  const AttendanceActionSuccess(this.message, {required this.isCheckedIn});
  @override
  List<Object?> get props => [message, isCheckedIn];
}

class AttendanceError extends AttendanceState {
  final String message;
  const AttendanceError(this.message);
  @override
  List<Object?> get props => [message];
}

// BLoC
class AttendanceBloc extends Bloc<AttendanceEvent, AttendanceState> {
  final AttendanceRepository _repo;
  bool _isCheckedIn = false;

  List<AttendanceLogEntity> _logs = const [];
  AttendanceSummaryEntity? _summary;
  List<AttendanceIssueEntity> _issues = const [];

  AttendanceBloc(this._repo) : super(const AttendanceInitial()) {
    on<FetchAttendanceLog>(_onFetch);
    on<FetchIssues>(_onFetchIssues);
    on<RaiseIssue>(_onRaiseIssue);
    on<CheckInRequested>(_onCheckIn);
    on<CheckOutRequested>(_onCheckOut);
  }

  AttendanceLoaded get _loaded => AttendanceLoaded(
    logs: _logs,
    summary: _summary,
    issues: _issues,
    isCheckedIn: _isCheckedIn,
  );

  Future<void> _onFetch(
    FetchAttendanceLog e,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    final results = await Future.wait([
      _repo.fetchLog(),
      _repo.fetchSummary(),
      _repo.fetchIssues(),
    ]);

    final (logs, logErr) = results[0] as (List<AttendanceLogEntity>, dynamic);
    final (summary, _) = results[1] as (AttendanceSummaryEntity?, dynamic);
    final (issues, _) = results[2] as (List<AttendanceIssueEntity>, dynamic);

    // Only the log call is fatal for the screen; summary/issues degrade
    // gracefully to their empty state.
    if (logErr != null && logs.isEmpty) {
      emit(
        AttendanceError(
          logErr.message as String? ?? 'Unable to load attendance.',
        ),
      );
      return;
    }

    _logs = logs;
    _summary = summary;
    _issues = issues;
    emit(_loaded);
  }

  Future<void> _onFetchIssues(
    FetchIssues e,
    Emitter<AttendanceState> emit,
  ) async {
    final (issues, err) = await _repo.fetchIssues();
    if (err == null) {
      _issues = issues;
      emit(_loaded);
    }
  }

  Future<void> _onRaiseIssue(
    RaiseIssue e,
    Emitter<AttendanceState> emit,
  ) async {
    emit(_loaded.copyWith(isSubmittingIssue: true));

    final (issue, err) = await _repo.raiseIssue(
      type: e.type,
      date: e.date,
      details: e.details,
    );

    if (issue != null) {
      _issues = [issue, ..._issues];
      emit(
        AttendanceIssueSubmitSuccess(
          issue,
          logs: _logs,
          summary: _summary,
          issues: _issues,
          isCheckedIn: _isCheckedIn,
        ),
      );
      // Settle back to a plain loaded state.
      emit(_loaded);
    } else {
      emit(
        AttendanceIssueSubmitFailure(
          err?.message ?? 'Unable to submit issue.',
          logs: _logs,
          summary: _summary,
          issues: _issues,
          isCheckedIn: _isCheckedIn,
        ),
      );
      emit(_loaded);
    }
  }

  Future<void> _onCheckIn(
    CheckInRequested e,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());

    // 1. Upload the uniform selfie (if captured) to get a hosted URL.
    String? photoUrl;
    if (e.photoFile != null) {
      final (url, uploadErr) = await _repo.uploadSelfie(e.photoFile!);
      // If the upload fails we still attempt the punch; the server will reply
      // PHOTO_REQUIRED if a photo is mandatory, which we surface below.
      if (uploadErr == null) photoUrl = url;
    }

    // 2. Clock in via the punch endpoint.
    final (ok, err) = await _repo.punch(
      kind: 'clock_in',
      lat: e.lat,
      lng: e.lng,
      accuracyMeters: e.accuracyMeters,
      photoUrl: photoUrl,
    );

    if (ok) {
      _isCheckedIn = true;
      emit(const AttendanceActionSuccess('Logged on duty', isCheckedIn: true));
    } else {
      emit(AttendanceError(err?.message ?? 'Unable to log on duty.'));
    }
  }

  Future<void> _onCheckOut(
    CheckOutRequested e,
    Emitter<AttendanceState> emit,
  ) async {
    emit(const AttendanceLoading());
    await Future.delayed(const Duration(milliseconds: 400));
    _isCheckedIn = false;
    emit(
      const AttendanceActionSuccess(
        'Checked out successfully!',
        isCheckedIn: false,
      ),
    );
  }
}
