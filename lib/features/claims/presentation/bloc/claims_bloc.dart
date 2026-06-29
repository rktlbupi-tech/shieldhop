import 'dart:io';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/claim_entities.dart';
import '../../domain/repositories/claims_repository.dart';

// ── Events ──────────────────────────────────────────────────────────────────
abstract class ClaimsEvent extends Equatable {
  const ClaimsEvent();
  @override
  List<Object?> get props => [];
}

/// Loads the screen: summary (for [period]) + recent claims.
class FetchClaimsOverview extends ClaimsEvent {
  final ClaimPeriod period;
  const FetchClaimsOverview({this.period = ClaimPeriod.thisMonth});
  @override
  List<Object?> get props => [period];
}

/// Re-fetches just the summary cards for a new period.
class ChangeClaimsPeriod extends ClaimsEvent {
  final ClaimPeriod period;
  const ChangeClaimsPeriod(this.period);
  @override
  List<Object?> get props => [period];
}

/// Submits a new claim. If [receiptFile] is set it is uploaded first and its
/// URL attached.
class AddClaim extends ClaimsEvent {
  final String category;
  final DateTime? date;
  final String description;
  final double amount;
  final File? receiptFile;
  const AddClaim({
    required this.category,
    this.date,
    required this.description,
    required this.amount,
    this.receiptFile,
  });
  @override
  List<Object?> get props => [category, date, description, amount, receiptFile];
}

// ── States ──────────────────────────────────────────────────────────────────
abstract class ClaimsState extends Equatable {
  const ClaimsState();
  @override
  List<Object?> get props => [];
}

class ClaimsInitial extends ClaimsState {
  const ClaimsInitial();
}

class ClaimsLoading extends ClaimsState {
  const ClaimsLoading();
}

class ClaimsLoaded extends ClaimsState {
  final ClaimsSummaryEntity? summary;
  final List<ClaimEntity> claims;
  final ClaimPeriod period;
  final bool isSubmitting;

  const ClaimsLoaded({
    this.summary,
    this.claims = const [],
    this.period = ClaimPeriod.thisMonth,
    this.isSubmitting = false,
  });

  ClaimsLoaded copyWith({
    ClaimsSummaryEntity? summary,
    List<ClaimEntity>? claims,
    ClaimPeriod? period,
    bool? isSubmitting,
  }) {
    return ClaimsLoaded(
      summary: summary ?? this.summary,
      claims: claims ?? this.claims,
      period: period ?? this.period,
      isSubmitting: isSubmitting ?? this.isSubmitting,
    );
  }

  @override
  List<Object?> get props => [summary, claims, period, isSubmitting];
}

/// Emitted once after a successful add; extends [ClaimsLoaded] so the screen
/// keeps rendering while a listener shows a confirmation.
class AddClaimSuccess extends ClaimsLoaded {
  const AddClaimSuccess({
    super.summary,
    super.claims,
    super.period,
  });
  @override
  List<Object?> get props => [...super.props, 'success'];
}

class AddClaimFailure extends ClaimsLoaded {
  final String errorMessage;
  const AddClaimFailure(
    this.errorMessage, {
    super.summary,
    super.claims,
    super.period,
  });
  @override
  List<Object?> get props => [...super.props, errorMessage];
}

class ClaimsError extends ClaimsState {
  final String message;
  const ClaimsError(this.message);
  @override
  List<Object?> get props => [message];
}

// ── BLoC ────────────────────────────────────────────────────────────────────
class ClaimsBloc extends Bloc<ClaimsEvent, ClaimsState> {
  final ClaimsRepository _repo;

  ClaimsSummaryEntity? _summary;
  List<ClaimEntity> _claims = const [];
  ClaimPeriod _period = ClaimPeriod.thisMonth;

  ClaimsBloc(this._repo) : super(const ClaimsInitial()) {
    on<FetchClaimsOverview>(_onFetch);
    on<ChangeClaimsPeriod>(_onChangePeriod);
    on<AddClaim>(_onAdd);
  }

  ClaimsLoaded get _loaded => ClaimsLoaded(
        summary: _summary,
        claims: _claims,
        period: _period,
      );

  Future<void> _onFetch(
    FetchClaimsOverview e,
    Emitter<ClaimsState> emit,
  ) async {
    emit(const ClaimsLoading());
    _period = e.period;

    final results = await Future.wait([
      _repo.fetchSummary(period: e.period),
      _repo.fetchClaims(),
    ]);

    final (summary, summaryErr) = results[0] as (ClaimsSummaryEntity?, dynamic);
    final (claims, claimsErr) = results[1] as (List<ClaimEntity>, dynamic);

    if (summaryErr != null && claimsErr != null && claims.isEmpty) {
      emit(ClaimsError(
          (claimsErr.message as String?) ?? 'Unable to load claims.'));
      return;
    }

    _summary = summary;
    _claims = claims;
    emit(_loaded);
  }

  Future<void> _onChangePeriod(
    ChangeClaimsPeriod e,
    Emitter<ClaimsState> emit,
  ) async {
    _period = e.period;
    final (summary, err) = await _repo.fetchSummary(period: e.period);
    if (err == null) _summary = summary;
    emit(_loaded);
  }

  Future<void> _onAdd(AddClaim e, Emitter<ClaimsState> emit) async {
    emit(_loaded.copyWith(isSubmitting: true));

    // 1. Upload the receipt first (if one was attached).
    String? receiptUrl;
    if (e.receiptFile != null) {
      final (url, uploadErr) = await _repo.uploadReceipt(e.receiptFile!);
      if (uploadErr != null) {
        emit(AddClaimFailure(
          'Receipt upload failed: ${uploadErr.message}',
          summary: _summary,
          claims: _claims,
          period: _period,
        ));
        emit(_loaded);
        return;
      }
      receiptUrl = url;
    }

    // 2. Create the claim.
    final claimDate =
        e.date == null ? null : _ymd(e.date!);
    final (claim, err) = await _repo.addClaim(
      category: e.category,
      claimDate: claimDate,
      description: e.description,
      amount: e.amount,
      receiptUrl: receiptUrl,
    );

    if (claim != null) {
      _claims = [claim, ..._claims];
      // Totals changed — refresh the summary for the current period.
      final (summary, _) = await _repo.fetchSummary(period: _period);
      if (summary != null) _summary = summary;
      emit(AddClaimSuccess(
        summary: _summary,
        claims: _claims,
        period: _period,
      ));
      emit(_loaded);
    } else {
      emit(AddClaimFailure(
        err?.message ?? 'Unable to submit claim.',
        summary: _summary,
        claims: _claims,
        period: _period,
      ));
      emit(_loaded);
    }
  }

  String _ymd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
