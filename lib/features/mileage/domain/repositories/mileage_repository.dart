import '../../../../core/errors/failures.dart';
import '../entities/mileage_entities.dart';

abstract class MileageRepository {
  Future<(MileageSummaryEntity?, Failure?)> fetchSummary({
    MileagePeriod period,
    String? date,
  });

  Future<(List<MileageTripEntity>, Failure?)> fetchTrips({
    MileagePeriod period,
    String? date,
    int limit,
  });

  /// Logs (or replaces) a day's travel.
  Future<(MileageTripEntity?, Failure?)> logDay({
    String? date,
    double? distanceMeters,
    double? odometerStart,
    double? odometerEnd,
    int? durationMinutes,
    String? source,
    String? startLabel,
    String? endLabel,
    String? vehicleId,
  });
}
