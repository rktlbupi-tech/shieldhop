import '../../domain/entities/user_entity.dart';

class UserModel {
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

  const UserModel({
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
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    final pub = json['publicationDetails'] as Map<String, dynamic>?;
    return UserModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      firstName: json['firstName']?.toString() ?? '',
      lastName: json['lastName']?.toString() ?? '',
      phone: json['phone']?.toString(),
      profileImage: json['profileImage']?.toString(),
      role: json['role']?.toString(),
      designation: json['designation']?.toString(),
      department: json['department']?.toString(),
      companyName: pub?['companyName']?.toString(),
      companyLogo: pub?['profileImage']?.toString(),
    );
  }

  UserEntity toEntity(String token) => UserEntity(
        id: id,
        email: email,
        firstName: firstName,
        lastName: lastName,
        phone: phone,
        profileImage: profileImage,
        role: role,
        designation: designation,
        department: department,
        companyName: companyName,
        companyLogo: companyLogo,
        token: token,
      );
}
