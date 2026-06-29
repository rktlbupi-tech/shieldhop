import 'package:equatable/equatable.dart';

class EmergencyContact extends Equatable {
  final String name;
  final String relation;
  final String countryCode;
  final String phone;
  final String? email;
  final bool notifyEmail;
  final bool notifySms;
  final bool isPrimary;

  const EmergencyContact({
    required this.name,
    required this.relation,
    required this.countryCode,
    required this.phone,
    this.email,
    this.notifyEmail = true,
    this.notifySms = false,
    this.isPrimary = false,
  });

  @override
  List<Object?> get props => [
        name,
        relation,
        countryCode,
        phone,
        email,
        notifyEmail,
        notifySms,
        isPrimary,
      ];

  Map<String, dynamic> toJson() => {
        'name': name,
        'relation': relation,
        'country_code': countryCode,
        'phone': phone,
        if (email != null && email!.isNotEmpty) 'email': email,
        'notify_email': notifyEmail,
        'notify_sms': notifySms,
        'is_primary': isPrimary,
      };

  factory EmergencyContact.fromJson(Map<String, dynamic> json) {
    return EmergencyContact(
      name: json['name']?.toString() ?? '',
      relation: json['relation']?.toString() ?? '',
      countryCode: json['country_code']?.toString() ?? json['countryCode']?.toString() ?? '+91',
      phone: json['phone']?.toString() ?? '',
      email: json['email']?.toString(),
      notifyEmail: json['notify_email'] == true || json['notifyEmail'] == true,
      notifySms: json['notify_sms'] == true || json['notifySms'] == true,
      isPrimary: json['is_primary'] == true || json['isPrimary'] == true,
    );
  }
}

class ProfileEntity extends Equatable {
  final String id;
  final String email;
  final String firstName;
  final String lastName;
  final String? phone;
  final String? profileImage;
  final String? designation;
  final String? department;
  final String? address;
  final String? employeeId;
  final DateTime? joinedAt;
  final String? companyName;
  final String? companyLogo;

  // Ported fields
  final String? profileCity;
  final String? profileCountry;
  final String? profilePostCode;
  final String? profileAddress;
  final bool? verified;
  final String? city;
  final String? country;
  final DateTime? createdAt;
  final List<EmergencyContact> emergencyContacts;
  final String? currentLocation;
  final String? latitude;
  final String? longitude;

  const ProfileEntity({
    required this.id,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.phone,
    this.profileImage,
    this.designation,
    this.department,
    this.address,
    this.employeeId,
    this.joinedAt,
    this.companyName,
    this.companyLogo,
    this.profileCity,
    this.profileCountry,
    this.profilePostCode,
    this.profileAddress,
    this.verified,
    this.city,
    this.country,
    this.createdAt,
    this.emergencyContacts = const [],
    this.currentLocation,
    this.latitude,
    this.longitude,
  });

  String get fullName => '$firstName $lastName'.trim();

  @override
  List<Object?> get props => [
        id,
        email,
        firstName,
        lastName,
        phone,
        profileImage,
        profileCity,
        profileCountry,
        profilePostCode,
        profileAddress,
        verified,
        city,
        country,
        createdAt,
        emergencyContacts,
        currentLocation,
        latitude,
        longitude,
      ];
}
