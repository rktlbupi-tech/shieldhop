import '../../domain/entities/attendance_entity.dart';

class AttendanceLogModel {
  final String id;
  final DateTime date;
  final DateTime? checkIn;
  final DateTime? checkOut;
  final String status;
  final double? workedHours;

  AttendanceLogModel({
    required this.id,
    required this.date,
    this.checkIn,
    this.checkOut,
    required this.status,
    this.workedHours,
  });

  /// Parses the `enterprise/app/attendance/log` item shape:
  /// `{ date, in, out, hours, status }`. Falls back to the older
  /// `checkIn/checkOut/workedHours` keys for resilience.
  factory AttendanceLogModel.fromJson(Map<String, dynamic> j) {
    final inRaw = j['in'] ?? j['checkIn'];
    final outRaw = j['out'] ?? j['checkOut'];
    final hoursRaw = j['hours'] ?? j['workedHours'];
    return AttendanceLogModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? j['date']?.toString() ?? '',
      date: DateTime.tryParse(j['date']?.toString() ?? '') ?? DateTime.now(),
      checkIn: inRaw != null ? DateTime.tryParse(inRaw.toString()) : null,
      checkOut: outRaw != null ? DateTime.tryParse(outRaw.toString()) : null,
      status: j['status']?.toString() ?? 'present',
      workedHours: (hoursRaw as num?)?.toDouble(),
    );
  }

  AttendanceLogEntity toEntity() => AttendanceLogEntity(
        id: id,
        date: date,
        checkIn: checkIn,
        checkOut: checkOut,
        status: status,
        workedHours: workedHours,
      );
}

class AttendanceSummaryModel {
  final double hoursWorked;
  final double hoursTarget;
  final double attendanceRate;
  final int lateArrivals;
  final int dutyDaysPresent;
  final int dutyDaysTotal;

  AttendanceSummaryModel({
    required this.hoursWorked,
    required this.hoursTarget,
    required this.attendanceRate,
    required this.lateArrivals,
    required this.dutyDaysPresent,
    required this.dutyDaysTotal,
  });

  /// Parses `enterprise/app/attendance/summary` `data`:
  /// ```
  /// {
  ///   "hours_this_week": { "worked": 0, "target": 8 },
  ///   "attendance_rate": 100,
  ///   "late_arrivals": 0,
  ///   "duty_days": { "present": 1, "total": 1 }
  /// }
  /// ```
  factory AttendanceSummaryModel.fromJson(Map<String, dynamic> j) {
    final hours = (j['hours_this_week'] as Map<String, dynamic>?) ?? const {};
    final duty = (j['duty_days'] as Map<String, dynamic>?) ?? const {};
    return AttendanceSummaryModel(
      hoursWorked: (hours['worked'] as num?)?.toDouble() ?? 0,
      hoursTarget: (hours['target'] as num?)?.toDouble() ?? 0,
      attendanceRate: (j['attendance_rate'] as num?)?.toDouble() ?? 0,
      lateArrivals: (j['late_arrivals'] as num?)?.toInt() ?? 0,
      dutyDaysPresent: (duty['present'] as num?)?.toInt() ?? 0,
      dutyDaysTotal: (duty['total'] as num?)?.toInt() ?? 0,
    );
  }

  AttendanceSummaryEntity toEntity() => AttendanceSummaryEntity(
        hoursWorked: hoursWorked,
        hoursTarget: hoursTarget,
        attendanceRate: attendanceRate,
        lateArrivals: lateArrivals,
        dutyDaysPresent: dutyDaysPresent,
        dutyDaysTotal: dutyDaysTotal,
      );
}

class AttendanceIssueModel {
  final String id;
  final String code;
  final String type;
  final DateTime? date;
  final String details;
  final String status;
  final String? hrResponse;
  final String? decidedBy;
  final DateTime? decidedAt;
  final DateTime? createdAt;

  AttendanceIssueModel({
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

  factory AttendanceIssueModel.fromJson(Map<String, dynamic> j) {
    DateTime? parse(dynamic v) =>
        v == null ? null : DateTime.tryParse(v.toString());
    return AttendanceIssueModel(
      id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
      code: j['code']?.toString() ?? '',
      type: j['type']?.toString() ?? 'other',
      date: parse(j['date']),
      details: j['details']?.toString() ?? '',
      status: j['status']?.toString() ?? 'pending',
      hrResponse: j['hr_response']?.toString(),
      decidedBy: j['decided_by']?.toString(),
      decidedAt: parse(j['decided_at']),
      createdAt: parse(j['created_at']),
    );
  }

  AttendanceIssueEntity toEntity() => AttendanceIssueEntity(
        id: id,
        code: code,
        type: type,
        date: date,
        details: details,
        status: status,
        hrResponse: hrResponse,
        decidedBy: decidedBy,
        decidedAt: decidedAt,
        createdAt: createdAt,
      );
}
