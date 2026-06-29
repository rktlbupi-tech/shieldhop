import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/claim_entities.dart';
import '../../domain/repositories/claims_repository.dart';
import '../datasources/claims_remote_datasource.dart';

class ClaimsRepositoryImpl implements ClaimsRepository {
  final ClaimsRemoteDatasource _ds;
  ClaimsRepositoryImpl(this._ds);

  @override
  Future<(ClaimsSummaryEntity?, Failure?)> fetchSummary({
    ClaimPeriod period = ClaimPeriod.thisMonth,
  }) async {
    try {
      return ((await _ds.fetchSummary(period: period)).entity, null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<ClaimEntity>, Failure?)> fetchClaims({int limit = 50}) async {
    try {
      final models = await _ds.fetchClaims(limit: limit);
      return (models.map((m) => m.entity).toList(), null);
    } on NotFoundFailure {
      return (const <ClaimEntity>[], null);
    } on Failure catch (f) {
      return (<ClaimEntity>[], f);
    } catch (e) {
      return (<ClaimEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(String?, Failure?)> uploadReceipt(File file) async {
    try {
      return (await _ds.uploadReceipt(file), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(ClaimEntity?, Failure?)> addClaim({
    required String category,
    String? claimDate,
    required String description,
    required double amount,
    String? receiptUrl,
  }) async {
    try {
      final model = await _ds.addClaim(
        category: category,
        claimDate: claimDate,
        description: description,
        amount: amount,
        receiptUrl: receiptUrl,
      );
      return (model.entity, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
