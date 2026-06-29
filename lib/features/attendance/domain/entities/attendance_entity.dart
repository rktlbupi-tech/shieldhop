import 'package:equatable/equatable.dart';

class AttendanceLogEntity extends Equatable {
  final String id;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;

  /// One of: on_time, late, present, absent, off, upcoming.
  final String status;
  final double? workedHours;

  const AttendanceLogEntity({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.workedHours,
  });

  @override
  List<Object?> get props => [id, date, checkIn, checkOut, status, workedHours];
}

/// The four stat cards at the top of the attendance log screen.
/// See `GET enterprise/app/attendance/summary`.
class AttendanceSummaryEntity extends Equatable {
  /// Hours worked so far this week (Mon→today).
  final double hoursWorked;

  /// Scheduled working days this week × 8h.
  final double hoursTarget;

  /// present / scheduled working days this month, as a percentage (1 decimal).
  final double attendanceRate;

  /// Late clock-ins this month.
  final int lateArrivals;

  /// Days clocked in this month.
  final int dutyDaysPresent;

  /// Scheduled working days this month.
  final int dutyDaysTotal;

  const AttendanceSummaryEntity({
    required this.hoursWorked,
    required this.hoursTarget,
    required this.attendanceRate,
    required this.lateArrivals,
    required this.dutyDaysPresent,
    required this.dutyDaysTotal,
  });

  @override
  List<Object?> get props => [
        hoursWorked,
        hoursTarget,
        attendanceRate,
        lateArrivals,
        dutyDaysPresent,
        dutyDaysTotal,
      ];
}

/// An attendance issue raised by the worker (e.g. a missing clock-out),
/// reviewed by HR/a manager. See `enterprise/app/attendance/issues`.
class AttendanceIssueEntity extends Equatable {
  final String id;

  /// Human reference shown to the user, e.g. "Q-8137".
  final String code;

  /// One of: medical_issue, missing_clock_in, missing_clock_out,
  /// late_arrival, wrong_time, other.
  final String type;

  /// The day the issue is about.
  final DateTime? date;
  final String details;

  /// One of: pending, approved, rejected.
  final String status;

  /// HR/Admin reply once decided (null while pending).
  final String? hrResponse;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime? createdAt;

  const AttendanceIssueEntity({
    required this.id,
    required this.code,
    required this.type,
    this.date,
    required this.details,
    required this.status,
    this.hrResponse,
    this.decidedBy,
    this.decidedAt,
    this.createdAt,
  });

  @override
  List<Object?> get props => [id, code, type, status, hrResponse];
}
