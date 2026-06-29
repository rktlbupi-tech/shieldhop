import '../../../../core/errors/failures.dart';
import '../../domain/entities/earning_entity.dart';
import '../../domain/repositories/earnings_repository.dart';
import '../datasources/earnings_remote_datasource.dart';

class EarningsRepositoryImpl implements EarningsRepository {
  final EarningsRemoteDatasource _ds;
  EarningsRepositoryImpl(this._ds);

  @override
  Future<(YearlyEarningsEntity?, Failure?)> fetchEarnings({int? year}) async {
    try {
      return ((await _ds.fetchEarnings(year: year)).entity, null);
    } on NotFoundFailure {
      return (null, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
