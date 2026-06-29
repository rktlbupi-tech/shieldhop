import 'package:equatable/equatable.dart';

class UserEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImage;
  final String? role;
  final String? designation;
  final String? department;
  final String? companyName;
  final String? companyLogo;
  final String token;

  const UserEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImage,
    this.role,
    this.designation,
    this.department,
    this.companyName,
    this.companyLogo,
    required this.token,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [id, email, firstName, lastName, token];
}
