import 'package:equatable/equatable.dart';

/// A labelled money line (salary component or reimbursement).
class EarningLineItem extends Equatable {
  final String label;
  final double amount;
  const EarningLineItem({required this.label, required this.amount});

  @override
  List<Object?> get props => [label, amount];
}

/// One month of the yearly Earnings view. See `GET /app/earnings`.
class EarningMonthEntity extends Equatable {
  final String period; // "2026-06"
  final String monthLabel; // "June 2026"
  final String? payDate; // YYYY-MM-DD
  final double total; // total_salary + total_reimbursements
  final List<EarningLineItem> salaryComponents;
  final double totalSalary;
  final List<EarningLineItem> reimbursements;
  final double totalReimbursements;

  const EarningMonthEntity({
    required this.period,
    required this.monthLabel,
    this.payDate,
    required this.total,
    this.salaryComponents = const [],
    this.totalSalary = 0,
    this.reimbursements = const [],
    this.totalReimbursements = 0,
  });

  @override
  List<Object?> get props => [period, monthLabel, total];
}

/// The whole Earnings screen payload for a year.
class YearlyEarningsEntity extends Equatable {
  final int year;
  final double totalEarningsYear;
  final List<EarningMonthEntity> months;

  const YearlyEarningsEntity({
    required this.year,
    this.totalEarningsYear = 0,
    this.months = const [],
  });

  @override
  List<Object?> get props => [year, totalEarningsYear, months];
}
