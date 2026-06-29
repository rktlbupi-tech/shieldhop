import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();
  @override
  List<Object?> get props => [];
}

class LoginSubmitted extends AuthEvent {
  final String email;
  final String password;
  const LoginSubmitted(this.email, this.password);
  @override
  List<Object?> get props => [email, password];
}

class LogoutRequested extends AuthEvent {
  const LogoutRequested();
}

class AuthCheckRequested extends AuthEvent {
  const AuthCheckRequested();
}

class SignupSubmitted extends AuthEvent {
  final String fullName;
  final String email;
  final String password;
  const SignupSubmitted(this.fullName, this.email, this.password);
  @override
  List<Object?> get props => [fullName, email, password];
}
