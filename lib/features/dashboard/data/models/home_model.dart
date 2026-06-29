import '../../domain/entities/home_entities.dart';

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());
String? _s(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

Map<String, dynamic> _m(dynamic v) =>
    (v as Map<String, dynamic>?) ?? const {};

HomeAttentionItem _attn(Map<String, dynamic> j) =>
    HomeAttentionItem(count: _i(j['count']), summary: _s(j['summary']));

HomeData homeFromJson(Map<String, dynamic> j) {
  final emp = _m(j['employee']);
  final duty = _m(j['duty']);
  final tasks = _m(j['tasks']);
  final duties = _m(j['duties']);
  final week = _m(j['attendance_week']);
  final mileage = _m(j['mileage']);
  final earnings = _m(j['earnings']);
  final attn = _m(j['needs_attention']);
  final vehicle = mileage['vehicle'] as Map<String, dynamic>?;
  final payslip = earnings['latest_payslip'] as Map<String, dynamic>?;

  return HomeData(
    employee: HomeEmployee(
      name: emp['name']?.toString() ?? 'Employee',
      orgName: _s(emp['org_name']),
      avatarUrl: _s(emp['avatar_url']),
    ),
    duty: HomeDuty(
      onDuty: duty['on_duty'] == true,
      statusLabel: duty['status_label']?.toString() ?? 'OFF DUTY',
      shift: _s(duty['shift']),
      loggedOnAt: _date(duty['logged_on_at']),
      site: _s(duty['site']),
      mileageToday: _d(duty['mileage_today']),
    ),
    tasks: HomeTasks(
      assigned: _i(tasks['assigned']),
      completed: _i(tasks['completed']),
      pending: _i(tasks['pending']),
      onTimePct: _i(tasks['on_time_pct']),
      evidenceCount: _i(tasks['evidence_count']),
      recent: ((tasks['recent'] as List<dynamic>?) ?? const [])
          .map((e) => HomeTaskItem(
                title: (e as Map<String, dynamic>)['title']?.toString() ?? '',
                status: e['status']?.toString() ?? '',
              ))
          .toList(),
    ),
    duties: HomeDuties(
      shiftsDone: _i(duties['shifts_done']),
      avgShiftMinutes: _i(duties['avg_shift_minutes']),
      totalHours: _d(duties['total_hours']),
      recent: ((duties['recent'] as List<dynamic>?) ?? const [])
          .map((e) => HomeDutyRecent(
                date: _date((e as Map<String, dynamic>)['date']),
                workedMinutes: _i(e['worked_minutes']),
              ))
          .toList(),
    ),
    attendanceWeek: HomeAttendanceWeek(
      days: ((week['days'] as List<dynamic>?) ?? const [])
          .map((e) => HomeAttendanceDay(
                day: (e as Map<String, dynamic>)['day']?.toString() ?? '',
                code: e['code']?.toString() ?? '-',
              ))
          .toList(),
      present: _i(week['present']),
      late: _i(week['late']),
      absent: _i(week['absent']),
      holiday: _i(week['holiday']),
    ),
    mileage: HomeMileage(
      monthTotalMiles: _d(mileage['month_total_miles']),
      vehicle: vehicle == null
          ? null
          : HomeVehicle(
              name: vehicle['name']?.toString() ?? '',
              registration: vehicle['registration']?.toString() ?? '',
              status: vehicle['status']?.toString() ?? '',
              fuelType: _s(vehicle['fuel_type']),
              color: _s(vehicle['color']),
              photoUrl: _s(vehicle['photo_url']),
            ),
      recentTrips: ((mileage['recent_trips'] as List<dynamic>?) ?? const [])
          .map((e) => HomeTrip(
                fromLabel: _s((e as Map<String, dynamic>)['from_label']),
                toLabel: _s(e['to_label']),
                date: _date(e['date']),
                miles: _d(e['miles']),
                amount: _d(e['amount']),
              ))
          .toList(),
    ),
    latestPayslip: payslip == null
        ? null
        : HomePayslip(
            id: payslip['id']?.toString() ?? '',
            monthLabel: payslip['month_label']?.toString() ?? '',
            netPay: _d(payslip['net_pay']),
            payDate: _s(payslip['pay_date']),
          ),
    needsAttention: HomeNeedsAttention(
      leavePending: _attn(_m(attn['leave_pending'])),
      pendingClaims: _attn(_m(attn['pending_claims'])),
      notificationsUnread: _i(_m(attn['notifications_unread'])['count']),
    ),
  );
}
