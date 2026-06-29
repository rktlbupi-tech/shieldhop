import 'dart:io';
import '../../../../core/errors/failures.dart';
import '../entities/claim_entities.dart';

abstract class ClaimsRepository {
  Future<(ClaimsSummaryEntity?, Failure?)> fetchSummary({ClaimPeriod period});

  Future<(List<ClaimEntity>, Failure?)> fetchClaims({int limit});

  /// Uploads a receipt image, returning its hosted URL.
  Future<(String?, Failure?)> uploadReceipt(File file);

  /// Creates a new claim (starts as in_review).
  Future<(ClaimEntity?, Failure?)> addClaim({
    required String category,
    String? claimDate,
    required String description,
    required double amount,
    String? receiptUrl,
  });
}
