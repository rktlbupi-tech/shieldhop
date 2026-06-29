import '../../domain/entities/duty_entities.dart';

DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;

List<String> _toStringList(dynamic v) =>
    (v as List<dynamic>?)?.map((e) => e.toString()).toList() ?? const [];

// ── Current duty ────────────────────────────────────────────────────────────

class DutyCurrentModel {
  final DutyShiftEntity? shift;
  final DutySiteEntity? site;
  final DutySupervisorEntity? supervisor;
  final DutyMonthSummaryEntity? thisMonth;

  DutyCurrentModel({this.shift, this.site, this.supervisor, this.thisMonth});

  factory DutyCurrentModel.fromJson(Map<String, dynamic> j) {
    final shift = j['shift'] as Map<String, dynamic>?;
    final site = j['site'] as Map<String, dynamic>?;
    final sup = j['supervisor'] as Map<String, dynamic>?;
    final month = j['this_month'] as Map<String, dynamic>?;

    return DutyCurrentModel(
      shift: shift == null
          ? null
          : DutyShiftEntity(
              startMinute: _toInt(shift['start_minute']),
              endMinute: _toInt(shift['end_minute']),
              start: shift['start']?.toString() ?? '',
              end: shift['end']?.toString() ?? '',
              dutyDays: _toStringList(shift['duty_days']),
              offDays: _toStringList(shift['off_days']),
            ),
      site: site == null
          ? null
          : DutySiteEntity(
              name: site['name']?.toString() ?? '',
              address: site['address']?.toString() ?? '',
              lat: (site['lat'] as num?)?.toDouble(),
              lng: (site['lng'] as num?)?.toDouble(),
            ),
      supervisor: sup == null
          ? null
          : DutySupervisorEntity(
              name: sup['name']?.toString() ?? '',
              phone: sup['phone']?.toString(),
            ),
      thisMonth: month == null
          ? null
          : DutyMonthSummaryEntity(
              daysCompleted: _toInt(month['days_completed']),
              totalHours: _toDouble(month['total_hours']),
              attendanceRate: _toDouble(month['attendance_rate']),
            ),
    );
  }

  DutyCurrentEntity toEntity() => DutyCurrentEntity(
        shift: shift,
        site: site,
        supervisor: supervisor,
        thisMonth: thisMonth,
      );
}

// ── Upcoming shifts ─────────────────────────────────────────────────────────

class UpcomingShiftModel {
  final String id;
  final DateTime? date;
  final String name;
  final String site;
  final String start;
  final String end;
  final String status;

  UpcomingShiftModel({
    required this.id,
    this.date,
    required this.name,
    required this.site,
    required this.start,
    required this.end,
    required this.status,
  });

  factory UpcomingShiftModel.fromJson(Map<String, dynamic> j) =>
      UpcomingShiftModel(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        date: _parseDate(j['date']),
        name: j['name']?.toString() ?? '',
        site: j['site']?.toString() ?? '',
        start: j['start']?.toString() ?? '',
        end: j['end']?.toString() ?? '',
        status: j['status']?.toString() ?? 'scheduled',
      );

  UpcomingShiftEntity toEntity() => UpcomingShiftEntity(
        id: id,
        date: date,
        name: name,
        site: site,
        start: start,
        end: end,
        status: status,
      );
}

// ── Today's tasks ───────────────────────────────────────────────────────────

class TodayTaskModel {
  final String id;
  final String title;
  final String status;
  final String rawStatus;

  TodayTaskModel({
    required this.id,
    required this.title,
    required this.status,
    required this.rawStatus,
  });

  factory TodayTaskModel.fromJson(Map<String, dynamic> j) => TodayTaskModel(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        title: j['title']?.toString() ?? '',
        status: j['status']?.toString() ?? 'pending',
        rawStatus: j['raw_status']?.toString() ?? '',
      );

  TodayTaskEntity toEntity() => TodayTaskEntity(
        id: id,
        title: title,
        status: status,
        rawStatus: rawStatus,
      );
}

// ── Shift history ───────────────────────────────────────────────────────────

class DutyHistoryModel {
  final DutyHistorySummaryEntity? summary;
  final List<DutyHistoryRowEntity> rows;

  DutyHistoryModel({this.summary, this.rows = const []});

  factory DutyHistoryModel.fromJson(Map<String, dynamic> j) {
    final s = j['summary'] as Map<String, dynamic>?;
    final rows = (j['rows'] as List<dynamic>?) ?? const [];
    return DutyHistoryModel(
      summary: s == null
          ? null
          : DutyHistorySummaryEntity(
              avgShiftMinutes: _toInt(s['avg_shift_minutes']),
              totalHours: _toDouble(s['total_hours']),
              shiftsDone: _toInt(s['shifts_done']),
            ),
      rows: rows
          .map((e) => DutyHistoryRowEntity(
                date: _parseDate((e as Map<String, dynamic>)['date']),
                start: _parseDate(e['start']),
                end: _parseDate(e['end']),
                site: e['site']?.toString() ?? '',
                durationMinutes: _toInt(e['duration_minutes']),
                status: e['status']?.toString() ?? 'completed',
              ))
          .toList(),
    );
  }

  DutyHistoryEntity toEntity() =>
      DutyHistoryEntity(summary: summary, rows: rows);
}

// ── Handover report ─────────────────────────────────────────────────────────

class HandoverReportModel {
  final String id;
  final String siteName;
  final String details;
  final String status;
  final DateTime? createdAt;

  HandoverReportModel({
    required this.id,
    required this.siteName,
    required this.details,
    required this.status,
    this.createdAt,
  });

  factory HandoverReportModel.fromJson(Map<String, dynamic> j) =>
      HandoverReportModel(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        siteName: j['site_name']?.toString() ?? '',
        details: j['details']?.toString() ?? '',
        status: j['status']?.toString() ?? 'open',
        createdAt: _parseDate(j['created_at']),
      );

  HandoverReportEntity toEntity() => HandoverReportEntity(
        id: id,
        siteName: siteName,
        details: details,
        status: status,
        createdAt: createdAt,
      );
}
