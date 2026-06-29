import '../../../../core/errors/failures.dart';
import '../entities/home_entities.dart';

abstract class HomeRepository {
  Future<(HomeData?, Failure?)> fetchHome();
}
