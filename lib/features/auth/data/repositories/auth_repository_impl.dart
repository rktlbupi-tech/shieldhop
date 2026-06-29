import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/errors/failures.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';
import '../../../../features/notifications/data/services/enterprise_fcm_service.dart';
import '../../../../core/services/firebase_logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final AuthRemoteDatasource _datasource;
  final SharedPreferences _prefs;

  AuthRepositoryImpl(this._datasource, this._prefs);

  @override
  Future<(UserEntity?, Failure?)> login(String email, String password) async {
    try {
      final (token, userModel) = await _datasource.login(email, password);
      final user = userModel.toEntity(token);
      await _saveSession(user);
      await EnterpriseFcmService.registerToken();
      return (user, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(UserEntity?, Failure?)> signup(
    String fullName,
    String email,
    String password,
  ) async {
    try {
      final (token, userModel) = await _datasource.signup(
        fullName,
        email,
        password,
      );
      final user = userModel.toEntity(token);
      await _saveSession(user);
      await EnterpriseFcmService.registerToken();
      return (user, null);
    } on Failure catch (f) {
      return (null, f);
    } catch (e) {
      return (null, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> logout() async {
    try {
      await EnterpriseFcmService.removeToken();
      await clearSession();
      return (true, null);
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<UserEntity?> getCachedUser() async {
    final token = _prefs.getString('auth_token');
    final id = _prefs.getString('user_id');
    final email = _prefs.getString('user_email');
    final firstName = _prefs.getString('user_first_name');
    if (token == null || id == null || email == null) return null;

    FirebaseLogger.setUserId(id);
    FirebaseLogger.setUserProperty(name: 'email', value: email);
    final role = _prefs.getString('user_role');
    if (role != null) {
      FirebaseLogger.setUserProperty(name: 'role', value: role);
    }

    return UserEntity(
      id: id,
      email: email,
      firstName: firstName ?? '',
      lastName: _prefs.getString('user_last_name') ?? '',
      phone: _prefs.getString('user_phone'),
      profileImage: _prefs.getString('user_avatar'),
      role: _prefs.getString('user_role'),
      companyName: _prefs.getString('company_name'),
      companyLogo: _prefs.getString('company_logo'),
      token: token,
    );
  }

  @override
  Future<void> clearSession() async {
    FirebaseLogger.setUserId('');
    await _prefs.remove('auth_token');
    await _prefs.remove('user_id');
    await _prefs.remove('user_email');
    await _prefs.remove('user_first_name');
    await _prefs.remove('user_last_name');
    await _prefs.remove('user_phone');
    await _prefs.remove('user_avatar');
    await _prefs.remove('user_role');
    await _prefs.remove('company_name');
    await _prefs.remove('company_logo');
  }

  Future<void> _saveSession(UserEntity user) async {
    FirebaseLogger.setUserId(user.id);
    FirebaseLogger.setUserProperty(name: 'email', value: user.email);
    if (user.role != null) {
      FirebaseLogger.setUserProperty(name: 'role', value: user.role!);
    }

    await _prefs.setString('auth_token', user.token);
    await _prefs.setString('user_id', user.id);
    await _prefs.setString('user_email', user.email);
    await _prefs.setString('user_first_name', user.firstName);
    await _prefs.setString('user_last_name', user.lastName);
    if (user.phone != null) {
      await _prefs.setString('user_phone', user.phone!);
    }
    if (user.profileImage != null) {
      await _prefs.setString('user_avatar', user.profileImage!);
    }
    if (user.role != null) {
      await _prefs.setString('user_role', user.role!);
    }
    if (user.companyName != null) {
      await _prefs.setString('company_name', user.companyName!);
    }
    if (user.companyLogo != null) {
      await _prefs.setString('company_logo', user.companyLogo!);
    }
  }
}
