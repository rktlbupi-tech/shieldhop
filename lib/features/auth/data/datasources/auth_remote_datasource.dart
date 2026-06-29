import '../../../../core/errors/failures.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/user_model.dart';

class AuthRemoteDatasource {
  final ApiClient _client;
  AuthRemoteDatasource(this._client);

  Future<(String token, UserModel user)> login(
      String email, String password) async {
    final response = await _client.post(
      ApiEndpoints.login,
      data: {'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ServerFailure(data['message']?.toString() ?? 'Login failed');
    }
    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return (token, UserModel.fromJson(userJson));
  }

  Future<(String token, UserModel user)> signup(
      String fullName, String email, String password) async {
    final parts = fullName.trim().split(' ');
    final firstName = parts.first;
    final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
    final response = await _client.post(
      ApiEndpoints.signup,
      data: {'firstName': firstName, 'lastName': lastName, 'email': email, 'password': password},
    );
    final data = response.data as Map<String, dynamic>;
    if (data['success'] != true) {
      throw ServerFailure(data['message']?.toString() ?? 'Signup failed');
    }
    final token = data['token']?.toString() ?? '';
    final userJson = data['user'] as Map<String, dynamic>? ?? {};
    return (token, UserModel.fromJson(userJson));
  }
}
