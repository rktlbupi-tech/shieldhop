import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

/// Parse a "#RRGGBB" hex string to a Color (falls back to brand blue).
Color leaveColor(String? hex) {
  if (hex == null || hex.isEmpty) return const Color(0xFF1877F2);
  var h = hex.replaceAll('#', '').trim();
  if (h.length == 6) h = 'FF$h';
  return Color(int.tryParse(h, radix: 16) ?? 0xFF1877F2);
}

/// A leave type from `GET /app/leave/types`.
class LeaveTypeEntity extends Equatable {
  final String id;
  final String code;
  final String name;
  final String label;
  final String color; // "#RRGGBB"
  final bool paid;
  final bool isWfh;
  final bool requiresAttachment;
  final double maxBalance;

  const LeaveTypeEntity({
    required this.id,
    required this.code,
    required this.name,
    required this.label,
    required this.color,
    this.paid = true,
    this.isWfh = false,
    this.requiresAttachment = false,
    this.maxBalance = 0,
  });

  @override
  List<Object?> get props => [id, code, label, paid, requiresAttachment];
}

/// A per-type balance row from `GET /app/leave/balances`.
class LeaveBalanceEntity extends Equatable {
  final String leaveTypeId;
  final String code;
  final String name;
  final String label;
  final String color;
  final bool paid;
  final int periodYear;
  final double opening;
  final double accrued;
  final double used;
  final double pending;
  final double adjusted;
  final double encashed;
  final double carriedForward;
  final double available;

  const LeaveBalanceEntity({
    required this.leaveTypeId,
    required this.code,
    required this.name,
    required this.label,
    required this.color,
    this.paid = true,
    this.periodYear = 0,
    this.opening = 0,
    this.accrued = 0,
    this.used = 0,
    this.pending = 0,
    this.adjusted = 0,
    this.encashed = 0,
    this.carriedForward = 0,
    this.available = 0,
  });

  @override
  List<Object?> get props => [leaveTypeId, available, used, pending];
}

class LeaveAttachment extends Equatable {
  final String url;
  final String fileName;
  const LeaveAttachment({required this.url, required this.fileName});

  Map<String, dynamic> toJson() => {'url': url, 'file_name': fileName};

  @override
  List<Object?> get props => [url, fileName];
}

class LeaveApprovalStage extends Equatable {
  final String stage; // "manager" | "hr"
  final String status; // "pending" | "approved" | "rejected"
  final String? approverName;
  final DateTime? actedAt;
  final String? note;

  const LeaveApprovalStage({
    required this.stage,
    required this.status,
    this.approverName,
    this.actedAt,
    this.note,
  });

  @override
  List<Object?> get props => [stage, status, approverName, actedAt, note];
}

/// A leave request (list row / detail) from `GET /app/leave`.
class LeaveRequestEntity extends Equatable {
  final String id;
  final String leaveTypeId;
  final String leaveTypeCode;
  final DateTime? from;
  final DateTime? to;
  final String halfDay; // "none" | "first_half" | "second_half"
  final String reason;
  final double applicableWorkdays;
  final List<LeaveAttachment> attachments;
  final String status;
  final List<LeaveApprovalStage> approvalChain;
  final DateTime? submittedAt;
  final DateTime? createdAt;

  const LeaveRequestEntity({
    required this.id,
    required this.leaveTypeId,
    required this.leaveTypeCode,
    this.from,
    this.to,
    this.halfDay = 'none',
    this.reason = '',
    this.applicableWorkdays = 0,
    this.attachments = const [],
    required this.status,
    this.approvalChain = const [],
    this.submittedAt,
    this.createdAt,
  });

  bool get isPending =>
      status == 'pending_manager' || status == 'pending_hr';

  /// Cancel is allowed when pending, or approved with a future start date.
  bool get canCancel {
    if (isPending) return true;
    if (status == 'approved' && from != null) {
      final today = DateTime.now();
      final start = DateTime(from!.year, from!.month, from!.day);
      final t = DateTime(today.year, today.month, today.day);
      return start.isAfter(t);
    }
    return false;
  }

  @override
  List<Object?> get props => [id, status, from, to, applicableWorkdays];
}

class LeaveHoliday extends Equatable {
  final DateTime? date;
  final String name;
  final bool optional;
  const LeaveHoliday({this.date, required this.name, this.optional = false});

  @override
  List<Object?> get props => [date, name, optional];
}

class LeaveOnLeave extends Equatable {
  final String workerId;
  final String workerName;
  final String? workerAvatarUrl;
  final String leaveTypeCode;
  final String color;
  final DateTime? from;
  final DateTime? to;
  final String halfDay;

  const LeaveOnLeave({
    required this.workerId,
    required this.workerName,
    this.workerAvatarUrl,
    required this.leaveTypeCode,
    required this.color,
    this.from,
    this.to,
    this.halfDay = 'none',
  });

  @override
  List<Object?> get props => [workerId, leaveTypeCode, from, to];
}

class LeaveCalendarEntity extends Equatable {
  final String month; // "YYYY-MM"
  final List<LeaveHoliday> holidays;
  final List<LeaveOnLeave> onLeave;

  const LeaveCalendarEntity({
    required this.month,
    this.holidays = const [],
    this.onLeave = const [],
  });

  @override
  List<Object?> get props => [month, holidays, onLeave];
}

/// Paged list wrapper.
class LeaveRequestPage extends Equatable {
  final List<LeaveRequestEntity> items;
  final int totalCount;
  final int page;
  final int totalPages;

  const LeaveRequestPage({
    this.items = const [],
    this.totalCount = 0,
    this.page = 1,
    this.totalPages = 1,
  });

  @override
  List<Object?> get props => [items, totalCount, page, totalPages];
}
