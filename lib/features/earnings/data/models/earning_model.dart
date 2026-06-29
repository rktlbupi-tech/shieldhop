import '../../domain/entities/earning_entity.dart';

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;

List<EarningLineItem> _lineItems(dynamic v) =>
    (v as List<dynamic>?)
        ?.map((e) => EarningLineItem(
              label: (e as Map<String, dynamic>)['label']?.toString() ?? '',
              amount: _toDouble(e['amount']),
            ))
        .toList() ??
    const [];

class YearlyEarningsModel {
  final YearlyEarningsEntity entity;
  YearlyEarningsModel(this.entity);

  factory YearlyEarningsModel.fromJson(Map<String, dynamic> j) {
    final months = (j['months'] as List<dynamic>?) ?? const [];
    return YearlyEarningsModel(YearlyEarningsEntity(
      year: (j['year'] as num?)?.toInt() ?? DateTime.now().year,
      totalEarningsYear: _toDouble(j['total_earnings_year']),
      months: months.map((m) {
        final mm = m as Map<String, dynamic>;
        return EarningMonthEntity(
          period: mm['period']?.toString() ?? '',
          monthLabel: mm['month_label']?.toString() ?? '',
          payDate: mm['pay_date']?.toString(),
          total: _toDouble(mm['total']),
          salaryComponents: _lineItems(mm['salary_components']),
          totalSalary: _toDouble(mm['total_salary']),
          reimbursements: _lineItems(mm['reimbursements']),
          totalReimbursements: _toDouble(mm['total_reimbursements']),
        );
      }).toList(),
    ));
  }
}
