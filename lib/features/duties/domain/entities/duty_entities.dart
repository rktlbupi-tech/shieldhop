import 'package:equatable/equatable.dart';

// ── Current duty (banner + site card + this-month summary) ──────────────────

/// The team member's active shift window. See `GET /app/duties/current`.
class DutyShiftEntity extends Equatable {
  final int startMinute; // minutes since midnight
  final int endMinute;
  final String start; // pre-formatted label, e.g. "09:00 AM"
  final String end;
  final List<String> dutyDays; // e.g. ["Mon","Tue",...]
  final List<String> offDays;

  const DutyShiftEntity({
    required this.startMinute,
    required this.endMinute,
    required this.start,
    required this.end,
    this.dutyDays = const [],
    this.offDays = const [],
  });

  @override
  List<Object?> get props => [startMinute, endMinute, start, end, dutyDays, offDays];
}

class DutySiteEntity extends Equatable {
  final String name;
  final String address;
  final double? lat;
  final double? lng;

  const DutySiteEntity({
    required this.name,
    required this.address,
    this.lat,
    this.lng,
  });

  @override
  List<Object?> get props => [name, address, lat, lng];
}

class DutySupervisorEntity extends Equatable {
  final String name;
  final String? phone;

  const DutySupervisorEntity({required this.name, this.phone});

  @override
  List<Object?> get props => [name, phone];
}

class DutyMonthSummaryEntity extends Equatable {
  final int daysCompleted;
  final double totalHours;
  final double attendanceRate;

  const DutyMonthSummaryEntity({
    required this.daysCompleted,
    required this.totalHours,
    required this.attendanceRate,
  });

  @override
  List<Object?> get props => [daysCompleted, totalHours, attendanceRate];
}

/// Whole payload of `GET /app/duties/current`. Any sub-object can be null when
/// the team member has no active posting / supervisor.
class DutyCurrentEntity extends Equatable {
  final DutyShiftEntity? shift;
  final DutySiteEntity? site;
  final DutySupervisorEntity? supervisor;
  final DutyMonthSummaryEntity? thisMonth;

  const DutyCurrentEntity({
    this.shift,
    this.site,
    this.supervisor,
    this.thisMonth,
  });

  @override
  List<Object?> get props => [shift, site, supervisor, thisMonth];
}

// ── Upcoming shifts ─────────────────────────────────────────────────────────

class UpcomingShiftEntity extends Equatable {
  final String id;
  final DateTime? date;
  final String name;
  final String site;
  final String start;
  final String end;
  final String status; // e.g. "scheduled"

  const UpcomingShiftEntity({
    required this.id,
    this.date,
    required this.name,
    required this.site,
    required this.start,
    required this.end,
    required this.status,
  });

  @override
  List<Object?> get props => [id, date, name, site, start, end, status];
}

// ── Today's tasks checklist ─────────────────────────────────────────────────

class TodayTaskEntity extends Equatable {
  final String id;
  final String title;
  final String status; // "completed" | "pending"
  final String rawStatus;

  const TodayTaskEntity({
    required this.id,
    required this.title,
    required this.status,
    required this.rawStatus,
  });

  bool get isCompleted => status == 'completed';

  @override
  List<Object?> get props => [id, title, status, rawStatus];
}

// ── Shift history ───────────────────────────────────────────────────────────

class DutyHistorySummaryEntity extends Equatable {
  final int avgShiftMinutes;
  final double totalHours;
  final int shiftsDone;

  const DutyHistorySummaryEntity({
    required this.avgShiftMinutes,
    required this.totalHours,
    required this.shiftsDone,
  });

  @override
  List<Object?> get props => [avgShiftMinutes, totalHours, shiftsDone];
}

class DutyHistoryRowEntity extends Equatable {
  final DateTime? date;
  final DateTime? start;
  final DateTime? end;
  final String site;
  final int durationMinutes;
  final String status; // "completed" | "late" | "present"

  const DutyHistoryRowEntity({
    this.date,
    this.start,
    this.end,
    required this.site,
    required this.durationMinutes,
    required this.status,
  });

  @override
  List<Object?> get props => [date, start, end, site, durationMinutes, status];
}

class DutyHistoryEntity extends Equatable {
  final DutyHistorySummaryEntity? summary;
  final List<DutyHistoryRowEntity> rows;

  const DutyHistoryEntity({this.summary, this.rows = const []});

  @override
  List<Object?> get props => [summary, rows];
}

/// Allowed `range` values for `GET /app/duties/history`.
enum DutyHistoryRange {
  lastMonth('last_month', 'Last Month'),
  last3Months('last_3_months', 'Last 3 Months'),
  last6Months('last_6_months', 'Last 6 Months'),
  lastYear('last_year', 'Last Year');

  final String value;
  final String label;
  const DutyHistoryRange(this.value, this.label);
}

// ── Handover report ─────────────────────────────────────────────────────────

class HandoverReportEntity extends Equatable {
  final String id;
  final String siteName;
  final String details;
  final String status; // e.g. "open"
  final DateTime? createdAt;

  const HandoverReportEntity({
    required this.id,
    required this.siteName,
    required this.details,
    required this.status,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, siteName, details, status, createdAt];
}
