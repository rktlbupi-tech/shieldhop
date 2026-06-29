import '../../domain/entities/profile_entity.dart';

class ProfileModel {
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

  // New fields from the old app structure
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

  ProfileModel({
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

  factory ProfileModel.fromJson(Map<String, dynamic> j) {
    final pub =
        j['publicationDetails'] as Map<String, dynamic>? ??
        j['publication_details'] as Map<String, dynamic>?;
    return ProfileModel(
      id: j['_id']?.toString() ?? j['id']?.toString() ?? '',
      email: j['email']?.toString() ?? '',
      firstName:
          j['firstName']?.toString() ?? j['first_name']?.toString() ?? '',
      lastName: j['lastName']?.toString() ?? j['last_name']?.toString() ?? '',
      phone: j['phone']?.toString(),
      profileImage:
          j['profileImage']?.toString() ?? j['profile_image']?.toString(),
      designation: j['designation']?.toString(),
      department: j['department']?.toString(),
      address: j['address']?.toString(),
      employeeId: j['employeeId']?.toString() ?? j['employee_id']?.toString(),
      joinedAt: j['joinedAt'] != null
          ? DateTime.tryParse(j['joinedAt'].toString())
          : (j['createdAt'] != null
                ? DateTime.tryParse(j['createdAt'].toString())
                : null),
      companyName:
          pub?['companyName']?.toString() ?? pub?['company_name']?.toString(),
      companyLogo:
          pub?['profileImage']?.toString() ?? pub?['profile_image']?.toString(),
      profileCity:
          j['profile_city']?.toString() ?? j['profileCity']?.toString(),
      profileCountry:
          j['profile_country']?.toString() ?? j['profileCountry']?.toString(),
      profilePostCode:
          j['profile_post_code']?.toString() ??
          j['profilePostCode']?.toString(),
      profileAddress:
          j['profile_address']?.toString() ?? j['profileAddress']?.toString(),
      verified: j['verified'] as bool?,
      city: j['city']?.toString(),
      country: j['country']?.toString(),
      createdAt: j['createdAt'] != null
          ? DateTime.tryParse(j['createdAt'].toString())
          : null,
      emergencyContacts:
          (j['emergency_contacts'] as List<dynamic>?)
              ?.map((e) => EmergencyContact.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      currentLocation:
          j['current_location']?.toString() ?? j['currentLocation']?.toString(),
      latitude: j['latitude']?.toString(),
      longitude: j['longitude']?.toString(),
    );
  }

  ProfileEntity toEntity() => ProfileEntity(
    id: id,
    email: email,
    firstName: firstName,
    lastName: lastName,
    phone: phone,
    profileImage: profileImage,
    designation: designation,
    department: department,
    address: address,
    employeeId: employeeId,
    joinedAt: joinedAt,
    companyName: companyName,
    companyLogo: companyLogo,
    profileCity: profileCity,
    profileCountry: profileCountry,
    profilePostCode: profilePostCode,
    profileAddress: profileAddress,
    verified: verified,
    city: city,
    country: country,
    createdAt: createdAt,
    emergencyContacts: emergencyContacts,
    currentLocation: currentLocation,
    latitude: latitude,
    longitude: longitude,
  );
}
