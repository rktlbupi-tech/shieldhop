import 'package:equatable/equatable.dart';

/// Whole Home screen payload. See `GET /app/home` (docs/api/home.md).
class HomeData extends Equatable {
  final HomeEmployee employee;
  final HomeDuty duty;
  final HomeTasks tasks;
  final HomeDuties duties;
  final HomeAttendanceWeek attendanceWeek;
  final HomeMileage mileage;
  final HomePayslip? latestPayslip;
  final HomeNeedsAttention needsAttention;

  const HomeData({
    required this.employee,
    required this.duty,
    required this.tasks,
    required this.duties,
    required this.attendanceWeek,
    required this.mileage,
    this.latestPayslip,
    required this.needsAttention,
  });

  @override
  List<Object?> get props => [
        employee,
        duty,
        tasks,
        duties,
        attendanceWeek,
        mileage,
        latestPayslip,
        needsAttention,
      ];
}

class HomeEmployee extends Equatable {
  final String name;
  final String? orgName;
  final String? avatarUrl;
  const HomeEmployee({required this.name, this.orgName, this.avatarUrl});
  @override
  List<Object?> get props => [name, orgName, avatarUrl];
}

class HomeDuty extends Equatable {
  final bool onDuty;
  final String statusLabel; // "ON DUTY" | "OFF DUTY"
  final String? shift; // "09:00-17:00"
  final DateTime? loggedOnAt;
  final String? site;
  final double mileageToday; // miles
  const HomeDuty({
    this.onDuty = false,
    this.statusLabel = 'OFF DUTY',
    this.shift,
    this.loggedOnAt,
    this.site,
    this.mileageToday = 0,
  });
  @override
  List<Object?> get props => [onDuty, statusLabel, shift, loggedOnAt, site, mileageToday];
}

class HomeTaskItem extends Equatable {
  final String title;
  final String status;
  const HomeTaskItem({required this.title, required this.status});
  @override
  List<Object?> get props => [title, status];
}

class HomeTasks extends Equatable {
  final int assigned;
  final int completed;
  final int pending;
  final int onTimePct;
  final int evidenceCount;
  final List<HomeTaskItem> recent;
  const HomeTasks({
    this.assigned = 0,
    this.completed = 0,
    this.pending = 0,
    this.onTimePct = 0,
    this.evidenceCount = 0,
    this.recent = const [],
  });
  @override
  List<Object?> get props => [assigned, completed, pending, onTimePct, evidenceCount, recent];
}

class HomeDutyRecent extends Equatable {
  final DateTime? date;
  final int workedMinutes;
  const HomeDutyRecent({this.date, this.workedMinutes = 0});
  @override
  List<Object?> get props => [date, workedMinutes];
}

class HomeDuties extends Equatable {
  final int shiftsDone;
  final int avgShiftMinutes;
  final double totalHours;
  final List<HomeDutyRecent> recent;
  const HomeDuties({
    this.shiftsDone = 0,
    this.avgShiftMinutes = 0,
    this.totalHours = 0,
    this.recent = const [],
  });
  @override
  List<Object?> get props => [shiftsDone, avgShiftMinutes, totalHours, recent];
}

class HomeAttendanceDay extends Equatable {
  final String day; // "Mon"
  final String code; // P | L | A | H | WO | -
  const HomeAttendanceDay({required this.day, required this.code});
  @override
  List<Object?> get props => [day, code];
}

class HomeAttendanceWeek extends Equatable {
  final List<HomeAttendanceDay> days;
  final int present;
  final int late;
  final int absent;
  final int holiday;
  const HomeAttendanceWeek({
    this.days = const [],
    this.present = 0,
    this.late = 0,
    this.absent = 0,
    this.holiday = 0,
  });
  @override
  List<Object?> get props => [days, present, late, absent, holiday];
}

class HomeVehicle extends Equatable {
  final String name;
  final String registration;
  final String status; // "Assigned" | "Personal"
  final String? fuelType;
  final String? color;
  final String? photoUrl;
  const HomeVehicle({
    required this.name,
    required this.registration,
    required this.status,
    this.fuelType,
    this.color,
    this.photoUrl,
  });
  @override
  List<Object?> get props => [name, registration, status, fuelType];
}

class HomeTrip extends Equatable {
  final String? fromLabel;
  final String? toLabel;
  final DateTime? date;
  final double miles;
  final double amount;
  const HomeTrip({this.fromLabel, this.toLabel, this.date, this.miles = 0, this.amount = 0});
  @override
  List<Object?> get props => [fromLabel, toLabel, date, miles, amount];
}

class HomeMileage extends Equatable {
  final double monthTotalMiles;
  final HomeVehicle? vehicle;
  final List<HomeTrip> recentTrips;
  const HomeMileage({
    this.monthTotalMiles = 0,
    this.vehicle,
    this.recentTrips = const [],
  });
  @override
  List<Object?> get props => [monthTotalMiles, vehicle, recentTrips];
}

class HomePayslip extends Equatable {
  final String id;
  final String monthLabel;
  final double netPay;
  final String? payDate;
  const HomePayslip({
    required this.id,
    required this.monthLabel,
    required this.netPay,
    this.payDate,
  });
  @override
  List<Object?> get props => [id, monthLabel, netPay, payDate];
}

class HomeAttentionItem extends Equatable {
  final int count;
  final String? summary;
  const HomeAttentionItem({this.count = 0, this.summary});
  @override
  List<Object?> get props => [count, summary];
}

class HomeNeedsAttention extends Equatable {
  final HomeAttentionItem leavePending;
  final HomeAttentionItem pendingClaims;
  final int notificationsUnread;
  const HomeNeedsAttention({
    this.leavePending = const HomeAttentionItem(),
    this.pendingClaims = const HomeAttentionItem(),
    this.notificationsUnread = 0,
  });
  @override
  List<Object?> get props => [leavePending, pendingClaims, notificationsUnread];
}
