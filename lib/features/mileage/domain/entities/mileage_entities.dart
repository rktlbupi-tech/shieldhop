import 'package:equatable/equatable.dart';

/// Period filter for the mileage summary + trips. See docs/api/track-mileage.md.
enum MileagePeriod {
  daily('daily', 'Daily'),
  weekly('weekly', 'Weekly'),
  monthly('monthly', 'Monthly'),
  yearly('yearly', 'Yearly');

  final String value;
  final String label;
  const MileagePeriod(this.value, this.label);

  /// "vs previous window" phrasing for the KPI subtitles.
  String get vsLabel {
    switch (this) {
      case MileagePeriod.daily:
        return 'vs yesterday';
      case MileagePeriod.weekly:
        return 'vs last week';
      case MileagePeriod.monthly:
        return 'vs last month';
      case MileagePeriod.yearly:
        return 'vs last year';
    }
  }
}

/// The four KPI cards. See `GET /app/mileage/summary`.
class MileageSummaryEntity extends Equatable {
  final String period;
  final String date;
  final String unit; // 'km' | 'mi'
  final String currency;
  final double totalDistanceMeters;
  final double distanceDeltaMeters;
  final int activeDays;
  final int activeDaysDelta;
  final int totalDurationMinutes;
  final int durationDeltaMinutes;
  final double estFuelCost;
  final double estFuelCostDelta;

  const MileageSummaryEntity({
    this.period = 'monthly',
    this.date = '',
    this.unit = 'km',
    this.currency = 'GBP',
    this.totalDistanceMeters = 0,
    this.distanceDeltaMeters = 0,
    this.activeDays = 0,
    this.activeDaysDelta = 0,
    this.totalDurationMinutes = 0,
    this.durationDeltaMinutes = 0,
    this.estFuelCost = 0,
    this.estFuelCostDelta = 0,
  });

  @override
  List<Object?> get props => [
        period,
        date,
        unit,
        currency,
        totalDistanceMeters,
        activeDays,
        totalDurationMinutes,
        estFuelCost,
      ];
}

/// A single day's consolidated mileage record. See `GET /app/mileage/trips`.
/// Every API field is preserved here even if not all are shown on screen.
class MileageTripEntity extends Equatable {
  final String id;
  final String? vehicleId;
  final DateTime? date;
  final String source; // 'gps' | 'manual'
  final double distanceMeters;
  final int durationMinutes;
  final String? startLabel;
  final String? endLabel;
  final double? odometerStart; // km, manual entries only
  final double? odometerEnd;
  final DateTime? clockInAt; // from attendance, may be null
  final DateTime? clockOutAt;
  final double estFuelCost;
  final double reimbursementAmount; // 0 for company vehicles
  final String currency;
  final DateTime? createdAt;

  const MileageTripEntity({
    required this.id,
    this.vehicleId,
    this.date,
    required this.source,
    required this.distanceMeters,
    required this.durationMinutes,
    this.startLabel,
    this.endLabel,
    this.odometerStart,
    this.odometerEnd,
    this.clockInAt,
    this.clockOutAt,
    this.estFuelCost = 0,
    this.reimbursementAmount = 0,
    this.currency = 'GBP',
    this.createdAt,
  });

  @override
  List<Object?> get props =>
      [id, date, source, distanceMeters, durationMinutes, startLabel, endLabel];
}
