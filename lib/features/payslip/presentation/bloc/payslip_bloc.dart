import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/payslip_entities.dart';
import '../../domain/repositories/payslip_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class PayslipEvent extends Equatable {
  const PayslipEvent();
  @override
  List<Object?> get props => [];
}

/// Loads the month picker and the newest payslip's detail.
class FetchPayslips extends PayslipEvent {
  const FetchPayslips();
}

/// Loads a specific month's full payslip.
class SelectPayslip extends PayslipEvent {
  final String id;
  const SelectPayslip(this.id);
  @override
  List<Object?> get props => [id];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class PayslipState extends Equatable {
  const PayslipState();
  @override
  List<Object?> get props => [];
}

class PayslipInitial extends PayslipState {
  const PayslipInitial();
}

class PayslipLoading extends PayslipState {
  const PayslipLoading();
}

class PayslipLoaded extends PayslipState {
  final List<PayslipListItem> list;
  final String? selectedId;
  final PayslipDetail? detail;
  final bool isLoadingDetail;

  const PayslipLoaded({
    this.list = const [],
    this.selectedId,
    this.detail,
    this.isLoadingDetail = false,
  });

  PayslipLoaded copyWith({
    List<PayslipListItem>? list,
    String? selectedId,
    PayslipDetail? detail,
    bool? isLoadingDetail,
  }) {
    return PayslipLoaded(
      list: list ?? this.list,
      selectedId: selectedId ?? this.selectedId,
      detail: detail ?? this.detail,
      isLoadingDetail: isLoadingDetail ?? this.isLoadingDetail,
    );
  }

  @override
  List<Object?> get props => [list, selectedId, detail, isLoadingDetail];
}

class PayslipError extends PayslipState {
  final String message;
  const PayslipError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class PayslipBloc extends Bloc<PayslipEvent, PayslipState> {
  final PayslipRepository _repo;

  List<PayslipListItem> _list = const [];

  PayslipBloc(this._repo) : super(const PayslipInitial()) {
    on<FetchPayslips>(_onFetchList);
    on<SelectPayslip>(_onSelect);
  }

  Future<void> _onFetchList(
    FetchPayslips e,
    Emitter<PayslipState> emit,
  ) async {
    emit(const PayslipLoading());
    final (list, err) = await _repo.fetchPayslips();
    if (err != null && list.isEmpty) {
      emit(PayslipError(err.message));
      return;
    }
    _list = list;
    if (list.isEmpty) {
      emit(const PayslipLoaded());
      return;
    }
    // Auto-load the newest payslip's detail.
    final firstId = list.first.id;
    emit(PayslipLoaded(list: list, selectedId: firstId, isLoadingDetail: true));
    final (detail, _) = await _repo.fetchPayslip(firstId);
    emit(PayslipLoaded(list: list, selectedId: firstId, detail: detail));
  }

  Future<void> _onSelect(
    SelectPayslip e,
    Emitter<PayslipState> emit,
  ) async {
    emit(PayslipLoaded(
        list: _list, selectedId: e.id, isLoadingDetail: true));
    final (detail, _) = await _repo.fetchPayslip(e.id);
    emit(PayslipLoaded(list: _list, selectedId: e.id, detail: detail));
  }
}
