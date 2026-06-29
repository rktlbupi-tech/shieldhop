import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/leave_entities.dart';
import '../../domain/repositories/leave_repository.dart';

// ── Apply (types + balances + submit) ───────────────────────────────────────
class LeaveApplyState extends Equatable {
  final bool loading;
  final List<LeaveTypeEntity> types;
  final List<LeaveBalanceEntity> balances;
  final String? loadError;
  final bool submitting;

  const LeaveApplyState({
    this.loading = true,
    this.types = const [],
    this.balances = const [],
    this.loadError,
    this.submitting = false,
  });

  LeaveApplyState copyWith({
    bool? loading,
    List<LeaveTypeEntity>? types,
    List<LeaveBalanceEntity>? balances,
    String? loadError,
    bool? submitting,
  }) =>
      LeaveApplyState(
        loading: loading ?? this.loading,
        types: types ?? this.types,
        balances: balances ?? this.balances,
        loadError: loadError,
        submitting: submitting ?? this.submitting,
      );

  double? availableFor(String leaveTypeId) {
    for (final b in balances) {
      if (b.leaveTypeId == leaveTypeId) return b.available;
    }
    return null;
  }

  @override
  List<Object?> get props => [loading, types, balances, loadError, submitting];
}

class LeaveApplyCubit extends Cubit<LeaveApplyState> {
  final LeaveRepository _repo;
  LeaveApplyCubit(this._repo) : super(const LeaveApplyState());

  /// Uploads an attachment, returns its URL (or null on failure).
  Future<String?> uploadAttachment(File file) async {
    final (url, _) = await _repo.uploadAttachment(file);
    return url;
  }

  Future<void> load() async {
    emit(state.copyWith(loading: true, loadError: null));
    final results = await Future.wait([_repo.fetchTypes(), _repo.fetchBalances()]);
    final (types, typesErr) = results[0] as (List<LeaveTypeEntity>, dynamic);
    final (balances, _) = results[1] as (List<LeaveBalanceEntity>, dynamic);
    if (typesErr != null && types.isEmpty) {
      emit(state.copyWith(loading: false, loadError: typesErr.message));
      return;
    }
    emit(state.copyWith(loading: false, types: types, balances: balances));
  }

  /// Returns (createdRequest, errorMessage). Exactly one is non-null.
  Future<(LeaveRequestEntity?, String?)> submit({
    required String leaveTypeId,
    required String from,
    required String to,
    String halfDay = 'none',
    String reason = '',
    List<LeaveAttachment> attachments = const [],
  }) async {
    emit(state.copyWith(submitting: true));
    final (req, err) = await _repo.applyLeave(
      leaveTypeId: leaveTypeId,
      from: from,
      to: to,
      halfDay: halfDay,
      reason: reason,
      attachments: attachments,
    );
    emit(state.copyWith(submitting: false));
    return (req, err?.message);
  }
}

// ── My requests (list + cancel) ─────────────────────────────────────────────
class LeaveRequestsState extends Equatable {
  final bool loading;
  final LeaveRequestPage? page;
  final String? error;
  final String? statusFilter;

  const LeaveRequestsState({
    this.loading = true,
    this.page,
    this.error,
    this.statusFilter,
  });

  LeaveRequestsState copyWith({
    bool? loading,
    LeaveRequestPage? page,
    String? error,
    String? statusFilter,
  }) =>
      LeaveRequestsState(
        loading: loading ?? this.loading,
        page: page ?? this.page,
        error: error,
        statusFilter: statusFilter ?? this.statusFilter,
      );

  @override
  List<Object?> get props => [loading, page, error, statusFilter];
}

class LeaveRequestsCubit extends Cubit<LeaveRequestsState> {
  final LeaveRepository _repo;
  LeaveRequestsCubit(this._repo) : super(const LeaveRequestsState());

  Future<void> fetch({String? status}) async {
    emit(state.copyWith(loading: true, error: null, statusFilter: status));
    final (page, err) = await _repo.fetchRequests(status: status, limit: 50);
    if (err != null && page == null) {
      emit(state.copyWith(loading: false, error: err.message));
      return;
    }
    emit(state.copyWith(loading: false, page: page ?? const LeaveRequestPage()));
  }

  /// Returns an error message on failure, null on success.
  Future<String?> cancel(String id) async {
    final (updated, err) = await _repo.cancelRequest(id);
    if (updated == null) return err?.message ?? 'Unable to cancel request.';
    // Replace the cancelled item in the current list.
    final current = state.page;
    if (current != null) {
      final items = current.items
          .map((r) => r.id == updated.id ? updated : r)
          .toList();
      emit(state.copyWith(
          page: LeaveRequestPage(
        items: items,
        totalCount: current.totalCount,
        page: current.page,
        totalPages: current.totalPages,
      )));
    }
    return null;
  }
}

// ── Balances ────────────────────────────────────────────────────────────────
class LeaveBalancesState extends Equatable {
  final bool loading;
  final List<LeaveBalanceEntity> balances;
  final String? error;
  const LeaveBalancesState(
      {this.loading = true, this.balances = const [], this.error});

  @override
  List<Object?> get props => [loading, balances, error];
}

class LeaveBalancesCubit extends Cubit<LeaveBalancesState> {
  final LeaveRepository _repo;
  LeaveBalancesCubit(this._repo) : super(const LeaveBalancesState());

  Future<void> load() async {
    emit(const LeaveBalancesState(loading: true));
    final (balances, err) = await _repo.fetchBalances();
    if (err != null && balances.isEmpty) {
      emit(LeaveBalancesState(loading: false, error: err.message));
      return;
    }
    emit(LeaveBalancesState(loading: false, balances: balances));
  }
}

// ── Calendar ─────────────────────────────────────────────────────────────────
class LeaveCalendarState extends Equatable {
  final bool loading;
  final LeaveCalendarEntity? calendar;
  final String month; // "YYYY-MM"
  final String? error;
  const LeaveCalendarState({
    this.loading = true,
    this.calendar,
    required this.month,
    this.error,
  });

  @override
  List<Object?> get props => [loading, calendar, month, error];
}

class LeaveCalendarCubit extends Cubit<LeaveCalendarState> {
  final LeaveRepository _repo;
  LeaveCalendarCubit(this._repo)
      : super(LeaveCalendarState(
          month: _ym(DateTime.now()),
        ));

  static String _ym(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}';

  Future<void> load(String month) async {
    emit(LeaveCalendarState(loading: true, month: month));
    final (cal, err) = await _repo.fetchCalendar(month: month);
    if (err != null && cal == null) {
      emit(LeaveCalendarState(loading: false, month: month, error: err.message));
      return;
    }
    emit(LeaveCalendarState(loading: false, month: month, calendar: cal));
  }
}
