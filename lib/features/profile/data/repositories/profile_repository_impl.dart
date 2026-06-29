import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/profile_entity.dart';
import '../../domain/repositories/profile_repository.dart';
import '../datasources/profile_remote_datasource.dart';

class ProfileRepositoryImpl implements ProfileRepository {
  final ProfileRemoteDatasource _ds;
  final SharedPreferences _prefs;

  ProfileRepositoryImpl(this._ds, this._prefs);

  @override
  Future<(ProfileEntity?, Failure?)> fetchProfile() async {
    try {
      final profile = (await _ds.fetchProfile()).toEntity();
      await _prefs.setString('user_first_name', profile.firstName);
      await _prefs.setString('user_last_name', profile.lastName);
      if (profile.profileImage != null) {
        await _prefs.setString('user_avatar', profile.profileImage!);
      }
      if (profile.companyName != null) {
        await _prefs.setString('company_name', profile.companyName!);
      }
      if (profile.companyLogo != null) {
        await _prefs.setString('company_logo', profile.companyLogo!);
      }
      return (profile, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> updateProfile(Map<String, dynamic> data) async {
    try { return (await _ds.updateProfile(data), null); }
    on Failure catch (f) { return (false, f); }
    catch (e) { return (false, UnknownFailure(e.toString())); }
  }

  @override
  Future<(String?, Failure?)> uploadMedia(File file) async {
    try {
      final url = await _ds.uploadMedia(file);
      return (url, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }
}
