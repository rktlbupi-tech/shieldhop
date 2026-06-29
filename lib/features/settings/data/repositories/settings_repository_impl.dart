import '../../../../core/errors/failures.dart';
import '../../domain/repositories/settings_repository.dart';
import '../datasources/settings_remote_datasource.dart';

class SettingsRepositoryImpl implements SettingsRepository {
  final SettingsRemoteDatasource _ds;
  SettingsRepositoryImpl(this._ds);

  @override
  Future<(bool, Failure?)> deleteAccount(Map<String, String> reason) async {
    try { return (await _ds.deleteAccount(reason), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }

  @override
  Future<(bool, Failure?)> contactUs(Map<String, String> data) async {
    try { return (await _ds.contactUs(data), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }

  @override
  Future<(String?, Failure?)> fetchAdminDetails() async {
    try { return (await _ds.fetchAdminDetails(), null); }
    on Failure catch (f) { return (null, f); }
    catch (e) { return (null, UnknownFailure(e.toString())); }
  }

  @override
  Future<(String?, Failure?)> fetchLegalTerms(String type) async {
    try { return (await _ds.fetchLegalTerms(type), null); }
    on Failure catch (f) { return (null, f); }
    catch (e) { return (null, UnknownFailure(e.toString())); }
  }

  @override
  Future<(bool, Failure?)> changePassword(Map<String, String> data) async {
    try { return (await _ds.changePassword(data), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }
}
