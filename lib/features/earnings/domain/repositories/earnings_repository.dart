import '../../../../core/errors/failures.dart';
import '../entities/earning_entity.dart';

abstract class EarningsRepository {
  Future<(YearlyEarningsEntity?, Failure?)> fetchEarnings({int? year});
}
