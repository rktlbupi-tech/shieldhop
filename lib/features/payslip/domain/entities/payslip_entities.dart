import 'package:equatable/equatable.dart';

/// A labelled money line (an earning or a deduction).
class PayLineItem extends Equatable {
  final String label;
  final double amount;
  const PayLineItem({required this.label, required this.amount});

  @override
  List<Object?> get props => [label, amount];
}

/// A row in the "Select Month" picker. See `GET /app/payslips`.
class PayslipListItem extends Equatable {
  final String id;
  final String period; // "2026-06"
  final String monthLabel; // "June 2026"
  final String? payDate; // YYYY-MM-DD
  final double netPay;

  const PayslipListItem({
    required this.id,
    required this.period,
    required this.monthLabel,
    this.payDate,
    required this.netPay,
  });

  @override
  List<Object?> get props => [id, period, monthLabel, payDate, netPay];
}

class PayslipEmployee extends Equatable {
  final String name;
  final String code; // may be ""
  final String? designation;
  final String? department;
  final String? location;
  final String? joinedDate; // YYYY-MM-DD

  const PayslipEmployee({
    required this.name,
    this.code = '',
    this.designation,
    this.department,
    this.location,
    this.joinedDate,
  });

  @override
  List<Object?> get props =>
      [name, code, designation, department, location, joinedDate];
}

/// The full payslip. See `GET /app/payslips/:id`.
class PayslipDetail extends Equatable {
  final PayslipEmployee employee;
  final String period;
  final String? payPeriodStart;
  final String? payPeriodEnd;
  final String? payDate;
  final String paymentMode;
  final List<PayLineItem> earnings;
  final double totalEarnings;
  final List<PayLineItem> deductions;
  final double totalDeductions;
  final double netPay;

  const PayslipDetail({
    required this.employee,
    required this.period,
    this.payPeriodStart,
    this.payPeriodEnd,
    this.payDate,
    this.paymentMode = '',
    this.earnings = const [],
    this.totalEarnings = 0,
    this.deductions = const [],
    this.totalDeductions = 0,
    this.netPay = 0,
  });

  @override
  List<Object?> get props => [period, netPay, totalEarnings, totalDeductions];
}
