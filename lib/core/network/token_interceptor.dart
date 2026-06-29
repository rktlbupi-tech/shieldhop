import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Intercepts 401 responses, clears the local session, and signals the app
/// to redirect to login. Actual navigation is handled by the auth guard in
/// GoRouter reacting to the removed token.
class TokenInterceptor extends Interceptor {
  final SharedPreferences _prefs;

  TokenInterceptor(this._prefs);

  @override
  void onError(DioException err, ErrorInterceptorHandler handler) {
    if (err.response?.statusCode == 401) {
      _prefs.remove('auth_token');
      _prefs.remove('user_id');
      _prefs.remove('user_email');
      _prefs.remove('user_first_name');
      _prefs.remove('user_last_name');
    }
    handler.next(err);
  }
}
