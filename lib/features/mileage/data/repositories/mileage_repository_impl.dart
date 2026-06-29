import '../../../../core/errors/failures.dart';
import '../../domain/entities/mileage_entities.dart';
import '../../domain/repositories/mileage_repository.dart';
import '../datasources/mileage_remote_datasource.dart';

class MileageRepositoryImpl implements MileageRepository {
  final MileageRemoteDatasource _ds;
  MileageRepositoryImpl(this._ds);

  @override
  Future<(MileageSummaryEntity?, Failure?)> fetchSummary({
    MileagePeriod period = MileagePeriod.monthly,
    String? date,
  }) async {
    try {
      return ((await _ds.fetchSummary(period: period, date: date)).entity, null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(List<MileageTripEntity>, Failure?)> fetchTrips({
    MileagePeriod period = MileagePeriod.monthly,
    String? date,
    int limit = 90,
  }) async {
    try {
      final models =
          await _ds.fetchTrips(period: period, date: date, limit: limit);
      return (models.map((m) => m.entity).toList(), null);
    } on NotFoundFailure {
      return (const <MileageTripEntity>[], null);
    } on Failure catch (f) {
      return (<MileageTripEntity>[], f);
    } catch (e) {
      return (<MileageTripEntity>[], UnknownFailure(e.toString()));
    }
  }

  @override
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
  }) async {
    try {
      final model = await _ds.logDay(
        date: date,
        distanceMeters: distanceMeters,
        odometerStart: odometerStart,
        odometerEnd: odometerEnd,
        durationMinutes: durationMinutes,
        source: source,
        startLabel: startLabel,
        endLabel: endLabel,
        vehicleId: vehicleId,
      );
      return (model.entity, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
