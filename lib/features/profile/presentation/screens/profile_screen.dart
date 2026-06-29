import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_places_flutter/google_places_flutter.dart';
import 'package:google_places_flutter/model/prediction.dart';
import 'package:image_picker/image_picker.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../config/di/injection.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_state.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';
import '../../../map/core/map_constants.dart' show googleMapAPiKey;

const String iconsPath = "assets/icons/";
const String commonImagePath = "assets/images/";

const double numD01 = 0.01;
const double numD02 = 0.02;
const double numD03 = 0.03;
const double numD04 = 0.04;
const double numD05 = 0.05;
const double numD06 = 0.06;
const double numD12 = 0.12;
const double numD13 = 0.13;
const double numD20 = 0.20;
const double numD25 = 0.25;
const double numD35 = 0.35;
const double numD37 = 0.37;
const double numD015 = 0.015;
const double numD032 = 0.032;
const double numD035 = 0.035;
const double numD028 = 0.028;

const Color colorLightGrey = Color(0xFFF5F5F5);
const Color colorTextFieldBorder = Color(0xFF858585);
const Color colorHint = Color(0xFFBDBDBD);
const Color colorTextFieldIcon = Color(0xFF757575);

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (_) => getIt<ProfileBloc>()..add(const FetchProfile()),
        ),
        BlocProvider(create: (_) => getIt<AuthBloc>()),
      ],
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) context.go(AppRoutes.login);
        },
        child: const _ProfileView(),
      ),
    );
  }
}

class _ProfileView extends StatefulWidget {
  const _ProfileView();

  @override
  State<_ProfileView> createState() => _ProfileViewState();
}

class _ProfileViewState extends State<_ProfileView> {
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _currentLocationController =
      TextEditingController();

  bool _isEditMode = false;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  String _latitude = "", _longitude = "";
  List<EmergencyContact> _emergencyContacts = [];
  bool _initialized = false;

  Future<void> _pickImage() async {
    if (!_isEditMode) return;
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _imageFile = File(image.path);
      });
    }
  }

  Future<void> _getCurrentLocation() async {
    try {
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      List<Placemark> placemarks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        String fullAddress = [
          if (place.street?.isNotEmpty ?? false) place.street,
          if (place.locality?.isNotEmpty ?? false) place.locality,
          if (place.administrativeArea?.isNotEmpty ?? false)
            place.administrativeArea,
          if (place.country?.isNotEmpty ?? false) place.country,
        ].whereType<String>().join(", ");
        setState(() {
          _cityController.text = place.locality ?? '';
          _countryController.text = place.country ?? '';
          _postCodeController.text = place.postalCode ?? '';
          _currentLocationController.text = fullAddress;
          _latitude = position.latitude.toString();
          _longitude = position.longitude.toString();
        });
      }
    } catch (e) {
      debugPrint("Error getting location: $e");
    }
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postCodeController.dispose();
    _countryController.dispose();
    _currentLocationController.dispose();
    super.dispose();
  }

  Future<void> _saveProfile() async {
    final Map<String, dynamic> updateData = {
      'first_name': _firstNameController.text.trim(),
      'last_name': _lastNameController.text.trim(),
      'phone': _phoneController.text.trim(),
      'email': _emailController.text.trim(),
      'profile_city': _cityController.text.trim(),
      'profile_country': _countryController.text.trim(),
      'profile_post_code': _postCodeController.text.trim(),
      'address': _addressController.text.trim(),
      'latitude': _latitude,
      'longitude': _longitude,
      'current_location': _currentLocationController.text.trim(),
      'emergency_contacts': _emergencyContacts.map((c) => c.toJson()).toList(),
    };

    if (_imageFile == null) {
      final profileState = context.read<ProfileBloc>().state;
      if (profileState is ProfileLoaded &&
          profileState.profile.profileImage != null) {
        String existingImg = profileState.profile.profileImage!;
        if (!existingImg.startsWith("file:///")) {
          updateData['profile_image'] = existingImg;
        }
      }
    }

    context.read<ProfileBloc>().add(UpdateProfile(updateData, imageFile: _imageFile));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        showBack: true,
        title: "My profile",
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
      ),
      body: BlocConsumer<ProfileBloc, ProfileState>(
        listener: (context, state) {
          if (state is ProfileUpdateSuccess) {
            final profileState = context.read<ProfileBloc>().state;
            if (profileState is ProfileLoaded) {
              final profile = profileState.profile;
              final prefs = getIt<SharedPreferences>();
              prefs.setString(
                'user_first_name',
                _firstNameController.text.trim(),
              );
              prefs.setString(
                'user_last_name',
                _lastNameController.text.trim(),
              );
              if (profile.profileImage != null) {
                prefs.setString('user_avatar', profile.profileImage!);
              }
            }

            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Profile updated successfully")),
            );
            setState(() {
              _isEditMode = false;
              _imageFile = null;
              _initialized = false;
            });
          }
        },
        builder: (context, state) {
          if (state is ProfileLoading && !_initialized)
            return const LoadingWidget();
          if (state is ProfileError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Error: ${state.message}",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () =>
                          context.read<ProfileBloc>().add(const FetchProfile()),
                      child: const Text("Retry"),
                    ),
                  ],
                ),
              ),
            );
          }

          final profile = state is ProfileLoaded ? state.profile : null;
          if (profile == null && !_initialized) return const LoadingWidget();

          if (profile != null && !_isEditMode && !_initialized) {
            _firstNameController.text = profile.firstName;
            _lastNameController.text = profile.lastName;
            _phoneController.text = profile.phone ?? '';
            _emailController.text = profile.email;
            _addressController.text =
                profile.profileAddress ?? profile.address ?? '';
            _cityController.text = profile.profileCity ?? profile.city ?? '';
            _postCodeController.text = profile.profilePostCode ?? '';
            _countryController.text =
                profile.profileCountry ?? profile.country ?? '';
            _currentLocationController.text = profile.currentLocation ?? '';
            _latitude = profile.latitude ?? '';
            _longitude = profile.longitude ?? '';
            _emergencyContacts = List.from(profile.emergencyContacts);
            _initialized = true;
          }

          return GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * numD06),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 20),
                    // Top Profile Widget (Hopper Style)
                    Container(
                      height: size.width * numD35,
                      decoration: BoxDecoration(
                        color: colorLightGrey,
                        borderRadius: BorderRadius.circular(
                          size.width * numD04,
                        ),
                      ),
                      child: Row(
                        children: [
                          GestureDetector(
                            onTap: _pickImage,
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.only(
                                    topLeft: Radius.circular(
                                      size.width * numD04,
                                    ),
                                    bottomLeft: Radius.circular(
                                      size.width * numD04,
                                    ),
                                  ),
                                  child: _imageFile != null
                                      ? Image.file(
                                          _imageFile!,
                                          fit: BoxFit.cover,
                                          width: size.width * numD37,
                                          height: size.width * numD35,
                                        )
                                      : () {
                                          String userProfileImage =
                                              profile?.profileImage ?? "";
                                          if (userProfileImage.startsWith(
                                            "https://dev-api.presshop.news:5019/",
                                          )) {
                                            userProfileImage = userProfileImage
                                                .replaceFirst(
                                                  "https://dev-api.presshop.news:5019/",
                                                  "https://dev-cdn.presshop.news/public/user/",
                                                );
                                          } else if (userProfileImage.startsWith(
                                            "http://dev-api.presshop.news:5019/",
                                          )) {
                                            userProfileImage = userProfileImage
                                                .replaceFirst(
                                                  "http://dev-api.presshop.news:5019/",
                                                  "https://dev-cdn.presshop.news/public/user/",
                                                );
                                          }
                                          if (userProfileImage.startsWith(
                                            "file:///",
                                          )) {
                                            userProfileImage = "";
                                          }
                                          return Image.network(
                                            userProfileImage.isEmpty
                                                ? "https://dev-cdn.presshop.news/public/avatarImages/default.png"
                                                : userProfileImage,
                                            errorBuilder:
                                                (
                                                  context,
                                                  error,
                                                  stackTrace,
                                                ) => Padding(
                                                  padding: EdgeInsets.all(
                                                    size.width * numD04,
                                                  ),
                                                  child: Image.asset(
                                                    "assets/images/app_logo.png",
                                                    fit: BoxFit.contain,
                                                    width: size.width * numD35,
                                                    height: size.width * numD35,
                                                  ),
                                                ),
                                            fit: BoxFit.cover,
                                            width: size.width * numD37,
                                            height: size.width * numD35,
                                          );
                                        }(),
                                ),
                                if (_isEditMode)
                                  Positioned(
                                    bottom: 8,
                                    right: 8,
                                    child: Container(
                                      padding: EdgeInsets.all(
                                        size.width * 0.005,
                                      ),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Container(
                                        padding: EdgeInsets.all(
                                          size.width * 0.005,
                                        ),
                                        decoration: const BoxDecoration(
                                          color: AppColors.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Icon(
                                          Icons.edit_outlined,
                                          color: Colors.white,
                                          size: size.width * numD04,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 15),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        profile != null
                                            ? "${profile.firstName} ${profile.lastName}"
                                            : "",
                                        style: commonTextStyle(
                                          size: size,
                                          fontSize: size.width * numD04,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        if (profile?.verified == true)
                                          Transform.translate(
                                            offset: const Offset(2, -1),
                                            child: Padding(
                                              padding: EdgeInsets.only(
                                                left: size.width * numD01,
                                              ),
                                              child: Image.asset(
                                                "${iconsPath}verified_badge.png",
                                                height: size.width * numD04,
                                                width: size.width * numD04,
                                              ),
                                            ),
                                          ),
                                        if (profile?.verified == true)
                                          Positioned(
                                            top: -size.width * numD02,
                                            left: size.width * numD06,
                                            child: Container(
                                              padding: EdgeInsets.symmetric(
                                                horizontal: size.width * numD01,
                                                vertical: size.width * 0.005,
                                              ),
                                              decoration: BoxDecoration(
                                                color: const Color(0xFF2D7ADE),
                                                borderRadius:
                                                    BorderRadius.circular(
                                                      size.width * numD01,
                                                    ),
                                              ),
                                              child: Text(
                                                "Verified",
                                                style: commonTextStyle(
                                                  size: size,
                                                  fontSize: size.width * numD02,
                                                  color: Colors.white,
                                                  fontWeight: FontWeight.w600,
                                                ),
                                              ),
                                            ),
                                          ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 5),
                                Text(
                                  "Joined - ${profile?.joinedAt != null ? profile!.joinedAt.toString().substring(0, 10) : 'N/A'}",
                                  style: commonTextStyle(
                                    size: size,
                                    fontSize: size.width * numD035,
                                    color: Colors.black,
                                    fontWeight: FontWeight.normal,
                                  ),
                                ),
                                if (profile?.city != null ||
                                    profile?.country != null)
                                  Text(
                                    "${profile?.city ?? ''}${profile?.city != null && profile?.country != null ? ', ' : ''}${profile?.country ?? ''}",
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: commonTextStyle(
                                      size: size,
                                      fontSize: size.width * numD032,
                                      color: Colors.black54,
                                      fontWeight: FontWeight.normal,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 30),

                    // Fields (Hopper Style)
                    _buildFieldLabel(size, "First name"),
                    _buildTextField(
                      size: size,
                      controller: _firstNameController,
                      hint: "Enter first name",
                      icon: "ic_user.png",
                      readOnly: !_isEditMode,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "Last name"),
                    _buildTextField(
                      size: size,
                      controller: _lastNameController,
                      hint: "Enter last name",
                      icon: "ic_user.png",
                      readOnly: !_isEditMode,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "Phone number"),
                    _buildTextField(
                      size: size,
                      controller: _phoneController,
                      hint: "Enter phone number",
                      icon: "ic_phone.png",
                      readOnly: !_isEditMode,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "Email address"),
                    _buildTextField(
                      size: size,
                      controller: _emailController,
                      hint: "Enter email address",
                      icon: "ic_email.png",
                      readOnly: true,
                      scale: 0.9,
                    ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "City"),
                    _isEditMode
                        ? Container(
                            height: size.width * numD12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                size.width * numD03,
                              ),
                              border: Border.all(
                                color: colorTextFieldBorder,
                                width: 1,
                              ),
                            ),
                            child: GooglePlaceAutoCompleteTextField(
                              textEditingController: _cityController,
                              googleAPIKey: googleMapAPiKey,
                              isCrossBtnShown: false,
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: size.width * numD032,
                                fontFamily: 'AirbnbCereal',
                              ),
                              inputDecoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter city",
                                hintStyle: TextStyle(
                                  color: colorHint,
                                  fontSize: size.width * numD035,
                                  fontFamily: 'AirbnbCereal',
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * numD02,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: size.width * numD015,
                                    ),
                                    child: Image.asset(
                                      "${iconsPath}ic_location.png",
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  maxHeight: size.width * numD04,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: size.width * numD02,
                                ),
                              ),
                              countries: const ["uk", "in"],
                              isLatLngRequired: false,
                              itemClick: (Prediction prediction) {
                                _cityController.text =
                                    prediction.description ?? "";
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ),
                          )
                        : _buildTextField(
                            size: size,
                            controller: _cityController,
                            hint: "Enter City",
                            icon: "ic_location.png",
                            readOnly: true,
                          ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "Postal code"),
                    _isEditMode
                        ? Container(
                            height: size.width * numD12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                size.width * numD03,
                              ),
                              border: Border.all(
                                color: colorTextFieldBorder,
                                width: 1,
                              ),
                            ),
                            child: GooglePlaceAutoCompleteTextField(
                              textEditingController: _postCodeController,
                              googleAPIKey: googleMapAPiKey,
                              isCrossBtnShown: false,
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: size.width * numD032,
                                fontFamily: 'AirbnbCereal',
                              ),
                              inputDecoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter postal code",
                                hintStyle: TextStyle(
                                  color: colorHint,
                                  fontSize: size.width * numD035,
                                  fontFamily: 'AirbnbCereal',
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * numD02,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: size.width * numD015,
                                    ),
                                    child: Image.asset(
                                      "${iconsPath}ic_location.png",
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  maxHeight: size.width * numD04,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: size.width * numD02,
                                ),
                              ),
                              countries: const ["uk", "in"],
                              isLatLngRequired: false,
                              itemClick: (Prediction prediction) {
                                _postCodeController.text =
                                    prediction.description ?? "";
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ),
                          )
                        : _buildTextField(
                            size: size,
                            controller: _postCodeController,
                            hint: "Enter postal code",
                            icon: "ic_location.png",
                            readOnly: true,
                          ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "Address"),
                    _isEditMode
                        ? Container(
                            height: size.width * numD12,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(
                                size.width * numD03,
                              ),
                              border: Border.all(
                                color: colorTextFieldBorder,
                                width: 1,
                              ),
                            ),
                            child: GooglePlaceAutoCompleteTextField(
                              textEditingController: _addressController,
                              googleAPIKey: googleMapAPiKey,
                              isCrossBtnShown: false,
                              textStyle: TextStyle(
                                color: Colors.black,
                                fontSize: size.width * numD032,
                                fontFamily: 'AirbnbCereal',
                              ),
                              inputDecoration: InputDecoration(
                                border: InputBorder.none,
                                hintText: "Enter address",
                                hintStyle: TextStyle(
                                  color: colorHint,
                                  fontSize: size.width * numD035,
                                  fontFamily: 'AirbnbCereal',
                                ),
                                prefixIcon: Padding(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: size.width * numD02,
                                  ),
                                  child: Container(
                                    margin: EdgeInsets.only(
                                      left: size.width * numD015,
                                    ),
                                    child: Image.asset(
                                      "${iconsPath}ic_location.png",
                                    ),
                                  ),
                                ),
                                prefixIconConstraints: BoxConstraints(
                                  maxHeight: size.width * numD04,
                                ),
                                contentPadding: EdgeInsets.symmetric(
                                  vertical: size.width * numD02,
                                ),
                              ),
                              countries: const ["uk", "in"],
                              isLatLngRequired: false,
                              itemClick: (Prediction prediction) {
                                _addressController.text =
                                    prediction.description ?? "";
                                FocusManager.instance.primaryFocus?.unfocus();
                              },
                            ),
                          )
                        : _buildTextField(
                            size: size,
                            controller: _addressController,
                            hint: "Enter Address",
                            icon: "ic_location.png",
                            readOnly: true,
                          ),
                    const SizedBox(height: 20),

                    _buildFieldLabel(size, "Current location"),
                    _buildTextField(
                      size: size,
                      controller: _currentLocationController,
                      hint: "Current location",
                      icon: "ic_location.png",
                      readOnly: true,
                    ),
                    const SizedBox(height: 30),

                    _buildEmergencyContactsSection(size),
                    const SizedBox(height: 20),

                    if (_isEditMode)
                      Row(
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: size.width * 0.12,
                              child: ElevatedButton(
                                onPressed: () {
                                  setState(() {
                                    _isEditMode = false;
                                    _initialized = false;
                                    _imageFile = null;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      size.width * numD04,
                                    ),
                                  ),
                                ),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: SizedBox(
                              height: size.width * 0.12,
                              child: ElevatedButton(
                                onPressed: _saveProfile,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      size.width * numD04,
                                    ),
                                  ),
                                ),
                                child: state is ProfileLoading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        "Save Changes",
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                              ),
                            ),
                          ),
                        ],
                      )
                    else
                      SizedBox(
                        width: double.infinity,
                        height: size.width * 0.12,
                        child: ElevatedButton(
                          onPressed: () {
                            setState(() {
                              _isEditMode = true;
                            });
                            _getCurrentLocation();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * numD04,
                              ),
                            ),
                          ),
                          child: const Text(
                            "Edit Profile",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildFieldLabel(Size size, String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        label,
        style: commonTextStyle(
          size: size,
          fontSize: size.width * numD032,
          color: Colors.black,
          fontWeight: FontWeight.normal,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required Size size,
    required TextEditingController controller,
    required String hint,
    required String icon,
    bool readOnly = true,
    double scale = 1.0,
  }) {
    return TextFormField(
      controller: controller,
      cursorColor: colorTextFieldIcon,
      obscureText: false,
      keyboardType: TextInputType.text,
      maxLines: 1,
      style: TextStyle(
        color: Colors.black,
        fontSize: size.width * numD032,
        fontFamily: 'AirbnbCereal',
      ),
      minLines: 1,
      readOnly: readOnly,
      decoration: InputDecoration(
        counterText: "",
        filled: true,
        fillColor: readOnly ? colorLightGrey : Colors.white,
        hintText: hint,
        hintStyle: TextStyle(
          color: colorHint,
          fontSize: size.width * numD035,
          fontFamily: 'AirbnbCereal',
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          borderSide: const BorderSide(width: 1, color: colorTextFieldBorder),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          borderSide: const BorderSide(width: 1, color: colorTextFieldBorder),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          borderSide: const BorderSide(width: 1, color: colorTextFieldBorder),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          borderSide: const BorderSide(width: 1, color: colorTextFieldBorder),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(size.width * 0.03),
          borderSide: const BorderSide(width: 1, color: colorTextFieldBorder),
        ),
        prefixIcon: Padding(
          padding: EdgeInsets.symmetric(horizontal: size.width * numD02),
          child: Container(
            margin: EdgeInsets.only(left: size.width * numD015),
            child: Transform.scale(
              scale: scale,
              child: Image.asset(
                "assets/icons/$icon",
                errorBuilder: (context, error, stackTrace) =>
                    const Icon(Icons.info_outline, size: 18),
              ),
            ),
          ),
        ),
        prefixIconConstraints: BoxConstraints(maxHeight: size.width * numD04),
        contentPadding: EdgeInsets.symmetric(vertical: size.width * numD02),
      ),
      textAlignVertical: TextAlignVertical.center,
      textCapitalization: TextCapitalization.words,
    );
  }

  Widget _buildEmergencyContactsSection(Size size) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildFieldLabel(size, 'Emergency contacts'),
            if (_isEditMode)
              GestureDetector(
                onTap: () => _showAddEditContactSheet(context, size),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.add, color: Colors.white, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        'Add',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: size.width * numD032,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        if (_emergencyContacts.isEmpty)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 18),
            decoration: BoxDecoration(
              color: colorLightGrey,
              borderRadius: BorderRadius.circular(size.width * numD03),
            ),
            child: Center(
              child: Text(
                'No emergency contacts added',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: size.width * numD032,
                ),
              ),
            ),
          )
        else
          ...List.generate(_emergencyContacts.length, (i) {
            final c = _emergencyContacts[i];
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: colorLightGrey,
                borderRadius: BorderRadius.circular(size.width * numD03),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.name,
                          style: commonTextStyle(
                            size: size,
                            fontSize: size.width * numD035,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${c.countryCode} ${c.phone}',
                          style: commonTextStyle(
                            size: size,
                            fontSize: size.width * numD032,
                            color: Colors.black54,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            c.relation,
                            style: TextStyle(
                              color: AppColors.primary,
                              fontSize: size.width * numD028,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (_isEditMode) ...[
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        size: 18,
                        color: Colors.black54,
                      ),
                      onPressed: () => _showAddEditContactSheet(
                        context,
                        size,
                        existing: c,
                        index: i,
                      ),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        size: 18,
                        color: Colors.red,
                      ),
                      onPressed: () =>
                          setState(() => _emergencyContacts.removeAt(i)),
                      constraints: const BoxConstraints(),
                      padding: const EdgeInsets.all(6),
                    ),
                  ],
                ],
              ),
            );
          }),
      ],
    );
  }

  void _showAddEditContactSheet(
    BuildContext ctx,
    Size size, {
    EmergencyContact? existing,
    int? index,
  }) {
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    final relationCtrl = TextEditingController(text: existing?.relation ?? '');
    final codeCtrl = TextEditingController(
      text: existing?.countryCode ?? '+91',
    );
    final phoneCtrl = TextEditingController(text: existing?.phone ?? '');
    final emailCtrl = TextEditingController(text: existing?.email ?? '');
    bool notifyEmail = existing?.notifyEmail ?? true;
    bool notifySms = existing?.notifySms ?? false;

    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => StatefulBuilder(
        builder: (ctx2, setSheet) => Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx2).viewInsets.bottom,
          ),
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    existing == null
                        ? 'Add emergency contact'
                        : 'Edit emergency contact',
                    style: commonTextStyle(
                      size: size,
                      fontSize: size.width * numD04,
                      color: Colors.black,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildFieldLabel(size, 'Name'),
                  _buildTextField(
                    size: size,
                    controller: nameCtrl,
                    hint: 'Full name',
                    icon: 'ic_user.png',
                    readOnly: false,
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel(size, 'Relation'),
                  _buildTextField(
                    size: size,
                    controller: relationCtrl,
                    hint: 'e.g. Spouse, Parent',
                    icon: 'ic_user.png',
                    readOnly: false,
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel(size, 'Phone number'),
                  Row(
                    children: [
                      SizedBox(
                        width: size.width * 0.22,
                        child: _buildTextField(
                          size: size,
                          controller: codeCtrl,
                          hint: '+91',
                          icon: 'ic_phone.png',
                          readOnly: false,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _buildTextField(
                          size: size,
                          controller: phoneCtrl,
                          hint: 'Phone number',
                          icon: 'ic_phone.png',
                          readOnly: false,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildFieldLabel(size, 'Email (optional)'),
                  _buildTextField(
                    size: size,
                    controller: emailCtrl,
                    hint: 'Email address',
                    icon: 'ic_email.png',
                    readOnly: false,
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: size.width * 0.14,
                    child: ElevatedButton(
                      onPressed: () {
                        if (nameCtrl.text.trim().isEmpty ||
                            phoneCtrl.text.trim().isEmpty)
                          return;
                        final contact = EmergencyContact(
                          name: nameCtrl.text.trim(),
                          relation: relationCtrl.text.trim(),
                          countryCode: codeCtrl.text.trim().isEmpty
                              ? '+91'
                              : codeCtrl.text.trim(),
                          phone: phoneCtrl.text.trim(),
                          email: emailCtrl.text.trim().isEmpty
                              ? null
                              : emailCtrl.text.trim(),
                          notifyEmail: notifyEmail,
                          notifySms: notifySms,
                        );
                        setState(() {
                          if (index != null) {
                            _emergencyContacts[index] = contact;
                          } else {
                            _emergencyContacts.add(contact);
                          }
                        });
                        Navigator.pop(ctx2);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            size.width * numD04,
                          ),
                        ),
                      ),
                      child: const Text(
                        'Save Contact',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

TextStyle commonTextStyle({
  required Size size,
  required double fontSize,
  required Color color,
  double? lineHeight,
  required FontWeight fontWeight,
  String? fontfamily = "AirbnbCereal",
}) {
  return TextStyle(
    fontFamily: fontfamily,
    fontWeight: fontWeight,
    fontSize: fontSize,
    height: lineHeight,
    color: color,
  );
}

Widget emilyLogoWidgetForPagesForEmployee(double size, String? companyLogo) {
  final double logoSize = size * 0.11;
  return UnconstrainedBox(
    child: Container(
      height: logoSize,
      width: logoSize,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey.shade50,
        border: Border.all(color: Colors.grey.shade300, width: 1.5),
      ),
      child: ClipOval(
        child: (companyLogo != null && companyLogo.isNotEmpty)
            ? Image.network(
                companyLogo,
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return const Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2.0,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        AppColors.primary,
                      ),
                    ),
                  );
                },
                errorBuilder: (ctx, e, st) => Image.asset(
                  'assets/images/app_logo.png',
                  fit: BoxFit.contain,
                ),
              )
            : Image.asset('assets/images/app_logo.png', fit: BoxFit.contain),
      ),
    ),
  );
}
