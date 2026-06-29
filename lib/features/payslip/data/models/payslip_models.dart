import '../../domain/entities/payslip_entities.dart';

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
String? _str(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

List<PayLineItem> _lines(dynamic v) =>
    (v as List<dynamic>?)
        ?.map((e) => PayLineItem(
              label: (e as Map<String, dynamic>)['label']?.toString() ?? '',
              amount: _toDouble(e['amount']),
            ))
        .toList() ??
    const [];

class PayslipListItemModel {
  final PayslipListItem entity;
  PayslipListItemModel(this.entity);

  factory PayslipListItemModel.fromJson(Map<String, dynamic> j) =>
      PayslipListItemModel(PayslipListItem(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        period: j['period']?.toString() ?? '',
        monthLabel: j['month_label']?.toString() ?? '',
        payDate: _str(j['pay_date']),
        netPay: _toDouble(j['net_pay']),
      ));
}

class PayslipDetailModel {
  final PayslipDetail entity;
  PayslipDetailModel(this.entity);

  factory PayslipDetailModel.fromJson(Map<String, dynamic> j) {
    final emp = (j['employee'] as Map<String, dynamic>?) ?? const {};
    final pp = (j['pay_period'] as Map<String, dynamic>?) ?? const {};
    return PayslipDetailModel(PayslipDetail(
      employee: PayslipEmployee(
        name: emp['name']?.toString() ?? '',
        code: emp['code']?.toString() ?? '',
        designation: _str(emp['designation']),
        department: _str(emp['department']),
        location: _str(emp['location']),
        joinedDate: _str(emp['joined_date']),
      ),
      period: j['period']?.toString() ?? '',
      payPeriodStart: _str(pp['start']),
      payPeriodEnd: _str(pp['end']),
      payDate: _str(j['pay_date']),
      paymentMode: j['payment_mode']?.toString() ?? '',
      earnings: _lines(j['earnings']),
      totalEarnings: _toDouble(j['total_earnings']),
      deductions: _lines(j['deductions']),
      totalDeductions: _toDouble(j['total_deductions']),
      netPay: _toDouble(j['net_pay']),
    ));
  }
}
