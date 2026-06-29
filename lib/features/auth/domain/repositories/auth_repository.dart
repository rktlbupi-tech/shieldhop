import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';

abstract class AuthRepository {
  Future<(UserEntity?, Failure?)> login(String email, String password);
  Future<(UserEntity?, Failure?)> signup(String fullName, String email, String password);
  Future<(bool, Failure?)> logout();
  Future<UserEntity?> getCachedUser();
  Future<void> clearSession();
}
