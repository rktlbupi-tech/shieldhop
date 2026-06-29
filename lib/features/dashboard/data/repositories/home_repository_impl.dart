import '../../../../core/errors/failures.dart';
import '../../domain/entities/home_entities.dart';
import '../../domain/repositories/home_repository.dart';
import '../datasources/home_remote_datasource.dart';

class HomeRepositoryImpl implements HomeRepository {
  final HomeRemoteDatasource _ds;
  HomeRepositoryImpl(this._ds);

  @override
  Future<(HomeData?, Failure?)> fetchHome() async {
    try {
      return (await _ds.fetchHome(), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
