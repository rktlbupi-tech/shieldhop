import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../domain/entities/profile_entity.dart';
import '../bloc/profile_bloc.dart';

const String iconsPath = "assets/icons/";
const double numD01 = 0.01;
const double numD02 = 0.02;
const double numD03 = 0.03;
const double numD04 = 0.04;
const double numD05 = 0.05;
const double numD06 = 0.06;
const double numD11 = 0.11;
const double numD16 = 0.16;
const double numD20 = 0.20;
const double numD25 = 0.25;
const double numD28 = 0.28;
const double numD60 = 0.60;
const double numD65 = 0.65;
const double numD70 = 0.70;
const double numD1 = 0.1;
const double numD036 = 0.036;
const double numD025 = 0.025;
const double appBarHeadingFontSize = 0.045;

const Color colorLightGrey = Color(0xFFF5F5F5);
const Color colorHint = Color(0xFFBDBDBD);

class DigitalIdScreen extends StatelessWidget {
  const DigitalIdScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<ProfileBloc>()..add(const FetchProfile()),
      child: const _DigitalIdView(),
    );
  }
}

class _DigitalIdView extends StatefulWidget {
  const _DigitalIdView();

  @override
  State<_DigitalIdView> createState() => _DigitalIdViewState();
}

class _DigitalIdViewState extends State<_DigitalIdView> {
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage(ImageSource source, ProfileEntity profile) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      final file = File(image.path);
      setState(() {
        _imageFile = file;
      });
      _updateProfileImage(file, profile);
    }
  }

  void _updateProfileImage(File file, ProfileEntity profile) {
    final Map<String, dynamic> updateData = {
      'first_name': profile.firstName,
      'last_name': profile.lastName,
      'phone': profile.phone ?? '',
      'email': profile.email,
      'profile_city': profile.city ?? profile.profileCity ?? '',
      'profile_country': profile.country ?? profile.profileCountry ?? '',
      'profile_post_code': profile.profilePostCode ?? '',
      'address': profile.address ?? profile.profileAddress ?? '',
      'emergency_contacts': profile.emergencyContacts
          .map((c) => c.toJson())
          .toList(),
      'latitude': profile.latitude ?? '',
      'longitude': profile.longitude ?? '',
      'current_location': profile.currentLocation ?? '',
    };

    context.read<ProfileBloc>().add(UpdateProfile(updateData, imageFile: file));
  }

  void _showPicker(Size size, ProfileEntity profile) {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext bc) {
        return SafeArea(
          child: Wrap(
            children: <Widget>[
              ListTile(
                leading: const Icon(Icons.photo_library),
                title: const Text('Photo Library'),
                onTap: () {
                  _pickImage(ImageSource.gallery, profile);
                  Navigator.of(context).pop();
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera),
                title: const Text('Camera'),
                onTap: () {
                  _pickImage(ImageSource.camera, profile);
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return BlocListener<ProfileBloc, ProfileState>(
      listener: (context, state) {
        if (state is ProfileUpdateSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Profile image updated successfully")),
          );
          setState(() {
            _imageFile = null;
          });
        } else if (state is ProfileError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Failed to update profile image: ${state.message}"),
            ),
          );
        }
      },
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, state) {
          final profile = state is ProfileLoaded ? state.profile : null;
          final isLoading = state is ProfileLoading;

          if (profile == null && state is ProfileLoading) {
            return const Scaffold(
              backgroundColor: Colors.white,
              body: LoadingWidget(),
            );
          }

          final String fullName = profile != null
              ? profile.fullName
              : "Loading...";

          String userProfileImage = profile?.profileImage ?? "";
          if (userProfileImage.startsWith(
            "https://dev-api.presshop.news:5019/",
          )) {
            userProfileImage = userProfileImage.replaceFirst(
              "https://dev-api.presshop.news:5019/",
              "https://dev-cdn.presshop.news/public/user/",
            );
          } else if (userProfileImage.startsWith(
            "http://dev-api.presshop.news:5019/",
          )) {
            userProfileImage = userProfileImage.replaceFirst(
              "http://dev-api.presshop.news:5019/",
              "https://dev-cdn.presshop.news/public/user/",
            );
          }
          if (userProfileImage.startsWith("file:///")) {
            userProfileImage = "";
          }

          final String pubName = profile?.companyName ?? "PressHop Media";
          // final String pubLogo = profile?.companyLogo ?? "";

          return Scaffold(
            backgroundColor: Colors.white,
            appBar: AppAppBar(
              title: "Digital id",
              showBack: true,
              backgroundColor: Colors.white,
              elevation: 0,
              titleSpacing: 0,
            ),
            body: Stack(
              children: [
                if (profile != null)
                  Container(
                    margin: EdgeInsets.only(
                      left: size.width * numD02,
                      right: size.width * numD02,
                      top: size.width * numD02,
                      bottom: size.width * numD1,
                    ),
                    decoration: BoxDecoration(
                      color: colorLightGrey,
                      borderRadius: BorderRadius.circular(size.width * numD03),
                      border: Border.all(width: 1.5, color: Colors.black),
                    ),
                    child: Stack(
                      alignment: Alignment.centerRight,
                      children: [
                        Align(
                          alignment: Alignment.topLeft,
                          child: Container(
                            padding: EdgeInsets.only(
                              left: size.width * numD03,
                              right: size.width * numD28,
                            ),
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [
                                  SizedBox(height: size.width * numD04),
                                  Stack(
                                    children: [
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          size.width * numD04,
                                        ),
                                        child: _imageFile != null
                                            ? Image.file(
                                                _imageFile!,
                                                height: size.width * numD60,
                                                width: size.width * numD70,
                                                fit: BoxFit.cover,
                                              )
                                            : CachedNetworkImage(
                                                imageUrl:
                                                    userProfileImage.isEmpty
                                                    ? "https://dev-cdn.presshop.news/public/avatarImages/default.png"
                                                    : userProfileImage,
                                                height: size.width * numD60,
                                                width: size.width * numD70,
                                                fit: BoxFit.cover,
                                                placeholder: (context, url) =>
                                                    const SizedBox.shrink(),
                                                errorWidget: (context, url, error) => Container(
                                                  height: size.width * numD65,
                                                  width: size.width * numD70,
                                                  decoration: BoxDecoration(
                                                    color: Colors.white,
                                                    border: Border.all(
                                                      color:
                                                          const Color.fromARGB(
                                                            255,
                                                            223,
                                                            223,
                                                            223,
                                                          ),
                                                    ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          size.width * numD04,
                                                        ),
                                                  ),
                                                  child: Column(
                                                    mainAxisAlignment:
                                                        MainAxisAlignment
                                                            .center,
                                                    children: [
                                                      Icon(
                                                        Icons.person,
                                                        size:
                                                            size.width * numD11,
                                                        color: Colors.grey,
                                                      ),
                                                      SizedBox(
                                                        height:
                                                            size.width * numD03,
                                                      ),
                                                      Padding(
                                                        padding:
                                                            const EdgeInsets.symmetric(
                                                              horizontal: 20,
                                                              vertical: 10,
                                                            ),
                                                        child: Text(
                                                          "Photo not available",
                                                          style:
                                                              commonTextStyle(
                                                                size: size,
                                                                fontSize:
                                                                    size.width *
                                                                    numD03,
                                                                color:
                                                                    colorHint,
                                                                fontWeight:
                                                                    FontWeight
                                                                        .normal,
                                                              ),
                                                          textAlign:
                                                              TextAlign.center,
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Positioned(
                                        bottom: size.width * numD02,
                                        right: size.width * numD02,
                                        child: InkWell(
                                          onTap: () {
                                            _showPicker(size, profile);
                                          },
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
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: size.width * numD04),
                                  Center(
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        Flexible(
                                          child: Text(
                                            fullName,
                                            style: commonTextStyle(
                                              size: size,
                                              fontSize: size.width * numD05,
                                              color: Colors.black,
                                              fontWeight: FontWeight.bold,
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: size.width * numD04),
                                  Container(
                                    width: size.width * numD60,
                                    padding: EdgeInsets.symmetric(
                                      vertical: size.width * numD03,
                                      horizontal: size.width * numD01,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.black,
                                      borderRadius: BorderRadius.circular(
                                        size.width * numD02,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(width: size.width * numD03),
                                        Image.asset(
                                          "assets/icons/ic_verified.png",
                                          height: size.width * numD06,
                                          width: size.width * numD06,
                                          color: Colors.white,
                                        ),
                                        SizedBox(width: size.width * numD03),
                                        Text(
                                          "Verified Employee",
                                          textAlign: TextAlign.start,
                                          style: commonTextStyle(
                                            size: size,
                                            fontSize: size.width * numD05,
                                            color: Colors.white,
                                            fontWeight: FontWeight.w400,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    width: size.width * numD60,
                                    alignment: Alignment.centerLeft,
                                    margin: EdgeInsets.only(
                                      top: size.width * numD04,
                                    ),
                                    padding: EdgeInsets.symmetric(
                                      vertical: size.width * numD03,
                                      horizontal: size.width * numD03,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        size.width * numD02,
                                      ),
                                      border: Border.all(
                                        width: 1.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    child: RichText(
                                      textAlign: TextAlign.start,
                                      text: TextSpan(
                                        text: "Digital ID Expires on\n",
                                        style: TextStyle(
                                          fontSize: size.width * numD036,
                                          color: Colors.black,
                                          fontWeight: FontWeight.w400,
                                          height: 1.5,
                                          fontFamily: "AirbnbCereal",
                                        ),
                                        children: [
                                          TextSpan(
                                            text: DateFormat("dd MMM yyyy")
                                                .format(
                                                  DateTime.now().add(
                                                    const Duration(days: 365),
                                                  ),
                                                ),
                                            style: TextStyle(
                                              fontSize: size.width * numD036,
                                              color: Colors.black,
                                              fontWeight: FontWeight.w600,
                                              height: 1.5,
                                              fontFamily: "AirbnbCereal",
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  SizedBox(height: size.width * numD04),
                                  Container(
                                    width: size.width * numD60,
                                    padding: EdgeInsets.symmetric(
                                      vertical: size.width * numD02,
                                    ),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(
                                        size.width * numD02,
                                      ),
                                      border: Border.all(
                                        width: 1.5,
                                        color: Colors.black,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        SizedBox(width: size.width * numD01),
                                        SizedBox(
                                          height: size.width * numD16,
                                          width: size.width * numD16,
                                          child: QrImageView(
                                            data:
                                                profile.employeeId ??
                                                profile.id,
                                            version: QrVersions.auto,
                                            padding: const EdgeInsets.all(2),
                                          ),
                                        ),
                                        SizedBox(width: size.width * numD01),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Text(
                                                pubName,
                                                style: TextStyle(
                                                  fontSize: size.width * numD03,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w600,
                                                  height: 1.2,
                                                  fontFamily: "AirbnbCereal",
                                                ),
                                              ),
                                              if (profile.city != null)
                                                Text(
                                                  "${profile.city}, ${profile.country ?? ''}",
                                                  style: TextStyle(
                                                    fontSize:
                                                        size.width * numD025,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.2,
                                                    fontFamily: "AirbnbCereal",
                                                  ),
                                                ),
                                              Text(
                                                "Employee ID: ${profile.employeeId ?? 'N/A'}",
                                                style: TextStyle(
                                                  fontSize:
                                                      size.width * numD025,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.2,
                                                  fontFamily: "AirbnbCereal",
                                                ),
                                              ),
                                              if (profile.address?.isNotEmpty ??
                                                  false)
                                                Text(
                                                  "Address: ${profile.address}",
                                                  maxLines: 2,
                                                  overflow:
                                                      TextOverflow.ellipsis,
                                                  style: TextStyle(
                                                    fontSize:
                                                        size.width * numD025,
                                                    color: Colors.black,
                                                    fontWeight: FontWeight.w400,
                                                    height: 1.2,
                                                    fontFamily: "AirbnbCereal",
                                                  ),
                                                ),
                                              Text(
                                                "Status: Active",
                                                style: TextStyle(
                                                  fontSize:
                                                      size.width * numD025,
                                                  color: Colors.black,
                                                  fontWeight: FontWeight.w400,
                                                  height: 1.2,
                                                  fontFamily: "AirbnbCereal",
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: size.width * numD02),
                                ],
                              ),
                            ),
                          ),
                        ),
                        RotatedBox(
                          quarterTurns: 1,
                          child: Container(
                            alignment: Alignment.center,
                            height: size.width * numD25,
                            decoration: BoxDecoration(
                              color: AppColors.primary,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(size.width * numD03),
                                topRight: Radius.circular(size.width * numD03),
                              ),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16.0,
                              ),
                              child: FittedBox(
                                fit: BoxFit.scaleDown,
                                child: Text(
                                  pubName.toUpperCase(),
                                  maxLines: 1,
                                  style: TextStyle(
                                    fontSize: pubName.length > 8
                                        ? size.width * 0.08
                                        : (pubName.length > 5
                                              ? size.width * 0.12
                                              : size.width * numD20),
                                    color: Colors.white,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: pubName.length > 8
                                        ? 4.0
                                        : (pubName.length > 5 ? 10.0 : 18.0),
                                    fontFamily: "AirbnbCereal",
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                if (isLoading)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.1),
                      child: const LoadingWidget(),
                    ),
                  ),
              ],
            ),
          );
        },
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
