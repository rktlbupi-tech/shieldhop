import '../../../../core/errors/failures.dart';
import '../entities/user_entity.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository _repository;
  LoginUseCase(this._repository);

  Future<(UserEntity?, Failure?)> call(String email, String password) {
    return _repository.login(email.trim().toLowerCase(), password);
  }
}
