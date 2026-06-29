import '../../domain/entities/mileage_entities.dart';

double _toDouble(dynamic v) => (v as num?)?.toDouble() ?? 0;
double? _toDoubleN(dynamic v) => (v as num?)?.toDouble();
int _toInt(dynamic v) => (v as num?)?.toInt() ?? 0;
DateTime? _parseDate(dynamic v) =>
    v == null ? null : DateTime.tryParse(v.toString());

class MileageSummaryModel {
  final MileageSummaryEntity entity;
  MileageSummaryModel(this.entity);

  factory MileageSummaryModel.fromJson(Map<String, dynamic> j) =>
      MileageSummaryModel(MileageSummaryEntity(
        period: j['period']?.toString() ?? 'monthly',
        date: j['date']?.toString() ?? '',
        unit: j['unit']?.toString() ?? 'km',
        currency: j['currency']?.toString() ?? 'GBP',
        totalDistanceMeters: _toDouble(j['total_distance_meters']),
        distanceDeltaMeters: _toDouble(j['distance_delta_meters']),
        activeDays: _toInt(j['active_days']),
        activeDaysDelta: _toInt(j['active_days_delta']),
        totalDurationMinutes: _toInt(j['total_duration_minutes']),
        durationDeltaMinutes: _toInt(j['duration_delta_minutes']),
        estFuelCost: _toDouble(j['est_fuel_cost']),
        estFuelCostDelta: _toDouble(j['est_fuel_cost_delta']),
      ));
}

class MileageTripModel {
  final MileageTripEntity entity;
  MileageTripModel(this.entity);

  factory MileageTripModel.fromJson(Map<String, dynamic> j) =>
      MileageTripModel(MileageTripEntity(
        id: j['id']?.toString() ?? j['_id']?.toString() ?? '',
        vehicleId: j['vehicle_id']?.toString(),
        date: _parseDate(j['date']),
        source: j['source']?.toString() ?? 'gps',
        distanceMeters: _toDouble(j['distance_meters']),
        durationMinutes: _toInt(j['duration_minutes']),
        startLabel: j['start_label']?.toString(),
        endLabel: j['end_label']?.toString(),
        odometerStart: _toDoubleN(j['odometer_start']),
        odometerEnd: _toDoubleN(j['odometer_end']),
        clockInAt: _parseDate(j['clock_in_at']),
        clockOutAt: _parseDate(j['clock_out_at']),
        estFuelCost: _toDouble(j['est_fuel_cost']),
        reimbursementAmount: _toDouble(j['reimbursement_amount']),
        currency: j['currency']?.toString() ?? 'GBP',
        createdAt: _parseDate(j['created_at']),
      ));
}
