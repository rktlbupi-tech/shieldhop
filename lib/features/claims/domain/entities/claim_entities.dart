import 'package:equatable/equatable.dart';

/// Period filter for the summary cards. See `GET /app/claims/summary`.
enum ClaimPeriod {
  thisMonth('this_month', 'This Month'),
  all('all', 'All Time');

  final String value;
  final String label;
  const ClaimPeriod(this.value, this.label);
}

/// Expense categories (the Add-expense dropdown). See `POST /app/claims`.
enum ClaimCategory {
  fuel('fuel', 'Fuel'),
  meal('meal', 'Meal'),
  parkingToll('parking_toll', 'Parking & Toll'),
  travel('travel', 'Travel'),
  accommodation('accommodation', 'Accommodation'),
  officeSupplies('office_supplies', 'Office Supplies'),
  other('other', 'Other');

  final String value;
  final String label;
  const ClaimCategory(this.value, this.label);

  static ClaimCategory fromValue(String? v) => ClaimCategory.values.firstWhere(
        (c) => c.value == v,
        orElse: () => ClaimCategory.other,
      );
}

/// One summary bucket (amount + claim count).
class ClaimBucketEntity extends Equatable {
  final double amount;
  final int count;
  const ClaimBucketEntity({this.amount = 0, this.count = 0});

  @override
  List<Object?> get props => [amount, count];
}

/// The four "My Expense Summary" cards. `submitted` is the period total
/// (`in_review + approved + rejected`).
class ClaimsSummaryEntity extends Equatable {
  final ClaimBucketEntity submitted;
  final ClaimBucketEntity inReview;
  final ClaimBucketEntity approved;
  final ClaimBucketEntity rejected;

  const ClaimsSummaryEntity({
    this.submitted = const ClaimBucketEntity(),
    this.inReview = const ClaimBucketEntity(),
    this.approved = const ClaimBucketEntity(),
    this.rejected = const ClaimBucketEntity(),
  });

  @override
  List<Object?> get props => [submitted, inReview, approved, rejected];
}

class ClaimEntity extends Equatable {
  final String id;
  final String category; // API value, e.g. "fuel"
  final String description;
  final DateTime? date;
  final double amount;
  final String currency; // e.g. "GBP"
  final String status; // in_review | approved | rejected
  final bool reimbursed;
  final String? receiptUrl;
  final String? decisionNote;
  final DateTime? createdAt;

  const ClaimEntity({
    required this.id,
    required this.category,
    required this.description,
    this.date,
    required this.amount,
    required this.currency,
    required this.status,
    this.reimbursed = false,
    this.receiptUrl,
    this.decisionNote,
    this.createdAt,
  });

  ClaimCategory get categoryEnum => ClaimCategory.fromValue(category);

  @override
  List<Object?> get props =>
      [id, category, description, date, amount, currency, status, reimbursed];
}
