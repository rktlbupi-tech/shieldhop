import '../../../../core/errors/failures.dart';
import '../../domain/entities/app_settings_entity.dart';
import '../../domain/repositories/app_settings_repository.dart';
import '../datasources/app_settings_remote_datasource.dart';

class AppSettingsRepositoryImpl implements AppSettingsRepository {
  final AppSettingsRemoteDatasource _ds;
  AppSettingsRepositoryImpl(this._ds);

  @override
  Future<(AppSettingsEntity?, Failure?)> fetch() async {
    try {
      return ((await _ds.fetch()).toEntity(), null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
