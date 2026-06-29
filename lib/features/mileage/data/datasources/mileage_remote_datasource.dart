import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../domain/entities/mileage_entities.dart';
import '../models/mileage_models.dart';

class MileageRemoteDatasource {
  final ApiClient _client;
  MileageRemoteDatasource(this._client);

  Future<MileageSummaryModel> fetchSummary({
    MileagePeriod period = MileagePeriod.monthly,
    String? date,
  }) async {
    final res = await _client.get(
      ApiEndpoints.mileageSummary,
      queryParameters: {
        'period': period.value,
        if (date != null) 'date': date,
      },
    );
    return MileageSummaryModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }

  Future<List<MileageTripModel>> fetchTrips({
    MileagePeriod period = MileagePeriod.monthly,
    String? date,
    int limit = 90,
  }) async {
    final res = await _client.get(
      ApiEndpoints.mileageTrips,
      queryParameters: {
        'period': period.value,
        if (date != null) 'date': date,
        'limit': limit,
      },
    );
    final data = res.data['data'] as List<dynamic>? ?? [];
    return data
        .map((e) => MileageTripModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// Logs (or replaces) a day. Send GPS [distanceMeters] OR a manual odometer
  /// pair. Returns the day record.
  Future<MileageTripModel> logDay({
    String? date,
    double? distanceMeters,
    double? odometerStart,
    double? odometerEnd,
    int? durationMinutes,
    String? source,
    String? startLabel,
    String? endLabel,
    String? vehicleId,
  }) async {
    final res = await _client.post(ApiEndpoints.mileageTrip, data: {
      if (date != null) 'date': date,
      if (distanceMeters != null) 'distance_meters': distanceMeters,
      if (odometerStart != null) 'odometer_start': odometerStart,
      if (odometerEnd != null) 'odometer_end': odometerEnd,
      if (durationMinutes != null) 'duration_minutes': durationMinutes,
      if (source != null) 'source': source,
      if (startLabel != null && startLabel.isNotEmpty) 'start_label': startLabel,
      if (endLabel != null && endLabel.isNotEmpty) 'end_label': endLabel,
      if (vehicleId != null && vehicleId.isNotEmpty) 'vehicle_id': vehicleId,
    });
    return MileageTripModel.fromJson(
        res.data['data'] as Map<String, dynamic>? ?? {});
  }
}
