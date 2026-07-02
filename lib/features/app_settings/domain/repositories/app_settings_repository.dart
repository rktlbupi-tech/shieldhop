import '../../../../core/errors/failures.dart';
import '../entities/app_settings_entity.dart';

abstract class AppSettingsRepository {
  Future<(AppSettingsEntity?, Failure?)> fetch();
}
