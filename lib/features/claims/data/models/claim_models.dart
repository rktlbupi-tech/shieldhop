import '../../domain/entities/claim_entities.dart';

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

ClaimBucketEntity _bucket(Map<String, dynamic>? j) => ClaimBucketEntity(
      amount: _toDouble(j?['amount']),
      count: _toInt(j?['count']),
    );

class ClaimsSummaryModel {
  final ClaimsSummaryEntity entity;
  ClaimsSummaryModel(this.entity);

  factory ClaimsSummaryModel.fromJson(Map<String, dynamic> j) =>
      ClaimsSummaryModel(ClaimsSummaryEntity(
        submitted: _bucket(j['submitted'] as Map<String, dynamic>?),
        inReview: _bucket(j['in_review'] as Map<String, dynamic>?),
        approved: _bucket(j['approved'] as Map<String, dynamic>?),
        rejected: _bucket(j['rejected'] as Map<String, dynamic>?),
      ));
}

class ClaimModel {
  final ClaimEntity entity;
  ClaimModel(this.entity);

  factory ClaimModel.fromJson(Map<String, dynamic> j) => ClaimModel(ClaimEntity(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        category: j['category']?.toString() ?? 'other',
        description: j['description']?.toString() ?? '',
        date: _parseDate(j['date']),
        amount: _toDouble(j['amount']),
        currency: j['currency']?.toString() ?? 'GBP',
        status: j['status']?.toString() ?? 'in_review',
        reimbursed: j['reimbursed'] == true,
        receiptUrl: j['receipt_url']?.toString(),
        decisionNote: j['decision_note']?.toString(),
        createdAt: _parseDate(j['created_at']),
      ));
}
