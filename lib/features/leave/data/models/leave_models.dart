import '../../domain/entities/leave_entities.dart';

double _d(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _i(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _date(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());
String? _s(dynamic v) {
  final s = v?.toString();
  return (s == null || s.isEmpty) ? null : s;
}

LeaveTypeEntity leaveTypeFromJson(Map<String, dynamic> j) => LeaveTypeEntity(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      label: j['label']?.toString() ?? j['name']?.toString() ?? '',
      color: j['color']?.toString() ?? '#1877F2',
      paid: j['paid'] != false,
      isWfh: j['is_wfh'] == true,
      requiresAttachment: j['requires_attachment'] == true,
      maxBalance: _d(j['max_balance']),
    );

LeaveBalanceEntity leaveBalanceFromJson(Map<String, dynamic> j) =>
    LeaveBalanceEntity(
      leaveTypeId: j['leave_type_id']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      name: j['name']?.toString() ?? '',
      label: j['label']?.toString() ?? j['name']?.toString() ?? '',
      color: j['color']?.toString() ?? '#1877F2',
      paid: j['paid'] != false,
      periodYear: _i(j['period_year']),
      opening: _d(j['opening']),
      accrued: _d(j['accrued']),
      used: _d(j['used']),
      pending: _d(j['pending']),
      adjusted: _d(j['adjusted']),
      encashed: _d(j['encashed']),
      carriedForward: _d(j['carried_forward']),
      available: _d(j['available']),
    );

LeaveRequestEntity leaveRequestFromJson(Map<String, dynamic> j) {
  final atts = (j['attachments'] as List<dynamic>?) ?? const [];
  final chain = (j['approval_chain'] as List<dynamic>?) ?? const [];
  return LeaveRequestEntity(
    id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
    leaveTypeId: j['leave_type_id']?.toString() ?? '',
    leaveTypeCode: j['leave_type_code']?.toString() ?? '',
    from: _date(j['from']),
    to: _date(j['to']),
    halfDay: j['half_day']?.toString() ?? 'none',
    reason: j['reason']?.toString() ?? '',
    applicableWorkdays: _d(j['applicable_workdays']),
    attachments: atts
        .map((a) => LeaveAttachment(
              url: (a as Map<String, dynamic>)['url']?.toString() ?? '',
              fileName: a['file_name']?.toString() ?? '',
            ))
        .toList(),
    status: j['status']?.toString() ?? 'pending_manager',
    approvalChain: chain
        .map((c) => LeaveApprovalStage(
              stage: (c as Map<String, dynamic>)['stage']?.toString() ?? '',
              status: c['status']?.toString() ?? 'pending',
              approverName: _s(c['approver_name']),
              actedAt: _date(c['acted_at']),
              note: _s(c['note']),
            ))
        .toList(),
    submittedAt: _date(j['submitted_at']),
    createdAt: _date(j['created_at']),
  );
}

LeaveRequestPage leaveRequestPageFromJson(Map<String, dynamic> data) {
  final items = (data['data'] as List<dynamic>?) ?? const [];
  return LeaveRequestPage(
    items: items
        .map((e) => leaveRequestFromJson(e as Map<String, dynamic>))
        .toList(),
    totalCount: _i(data['totalCount']),
    page: data['page'] == null ? 1 : _i(data['page']),
    totalPages: data['totalPages'] == null ? 1 : _i(data['totalPages']),
  );
}

LeaveCalendarEntity leaveCalendarFromJson(Map<String, dynamic> j) {
  final holidays = (j['holidays'] as List<dynamic>?) ?? const [];
  final onLeave = (j['on_leave'] as List<dynamic>?) ?? const [];
  return LeaveCalendarEntity(
    month: j['month']?.toString() ?? '',
    holidays: holidays
        .map((h) => LeaveHoliday(
              date: _date((h as Map<String, dynamic>)['date']),
              name: h['name']?.toString() ?? '',
              optional: h['optional'] == true,
            ))
        .toList(),
    onLeave: onLeave
        .map((o) => LeaveOnLeave(
              workerId: (o as Map<String, dynamic>)['worker_id']?.toString() ?? '',
              workerName: o['worker_name']?.toString() ?? '',
              workerAvatarUrl: _s(o['worker_avatar_url']),
              leaveTypeCode: o['leave_type_code']?.toString() ?? '',
              color: o['color']?.toString() ?? '#1877F2',
              from: _date(o['from']),
              to: _date(o['to']),
              halfDay: o['half_day']?.toString() ?? 'none',
            ))
        .toList(),
  );
}
