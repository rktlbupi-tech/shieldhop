import '../../../../core/errors/failures.dart';
import '../../domain/repositories/sos_repository.dart';
import '../datasources/sos_remote_datasource.dart';

class SosRepositoryImpl implements SosRepository {
  final SosRemoteDataSource _ds;

  SosRepositoryImpl(this._ds);

  @override
  Future<(bool, Failure?)> startSos({required double lat, required double lng}) async {
    try {
      final success = await _ds.startSos(lat: lat, lng: lng);
      return (success, null);
    } on Failure catch (f) {
      return (false, f);
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> stopSos() async {
    try {
      final success = await _ds.stopSos();
      return (success, null);
    } on Failure catch (f) {
      return (false, f);
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }
}
