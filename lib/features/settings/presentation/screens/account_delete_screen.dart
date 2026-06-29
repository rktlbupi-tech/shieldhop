import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/config/di/injection.dart';
import 'package:presshop_enterprise/config/routes/app_router.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import '../bloc/settings_bloc.dart';

class AccountDeleteScreen extends StatelessWidget {
  const AccountDeleteScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<SettingsBloc>(),
      child: const _AccountDeleteScreenContent(),
    );
  }
}

class _AccountDeleteScreenContent extends StatefulWidget {
  const _AccountDeleteScreenContent();

  @override
  State<_AccountDeleteScreenContent> createState() =>
      _AccountDeleteScreenContentState();
}

class _AccountDeleteScreenContentState
    extends State<_AccountDeleteScreenContent> {
  final List<Map<String, String>> purposeData = [
    {"title": "I don't like the app"},
    {"title": "Found a better alternative app"},
    {"title": "I have another Presshop Account"},
    {"title": "No longer using the app"},
    {"title": "App is too complicated or hard to use"},
    {"title": "Technical issues (e.g., bugs, crashes)"},
    {"title": "Privacy or data concerns"},
    {"title": "Other"},
  ];
  Map<String, String> selectReason = {};

  @override
  Widget build(BuildContext context) {
    var size = MediaQuery.of(context).size;
    final bool isIpad = size.width > 600;

    return BlocListener<SettingsBloc, SettingsState>(
      listener: (context, state) async {
        if (state is SettingsSuccess) {
          final prefs = getIt<SharedPreferences>();
          await prefs.clear();
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  state.message,
                  style: const TextStyle(fontFamily: 'AirbnbCereal'),
                ),
                backgroundColor: Colors.green,
              ),
            );
            context.go(AppRoutes.onboarding);
          }
        } else if (state is SettingsError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                state.message,
                style: const TextStyle(fontFamily: 'AirbnbCereal'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppAppBar(
          showBack: true,
          title: "Delete account",
          elevation: 0,
          centerTitle: false,
          titleSpacing: 0,
          backgroundColor: Colors.white,
        ),
        body: BlocBuilder<SettingsBloc, SettingsState>(
          builder: (context, state) {
            return Padding(
              padding: EdgeInsets.all(size.width * 0.045),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  SizedBox(height: size.height * 0.02),
                  Text(
                    "We’re sorry to see you go! If you choose to delete your account, it will be permanently removed from our system. Your phone number and email address will also be permanently erased. Are you absolutely certain you want to leave us forever?",
                    style: TextStyle(
                      fontSize: size.width * 0.035,
                      color: Colors.red,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(height: size.height * 0.02),
                  Text(
                    "Please let us know your reason for deleting the app :- ",
                    style: TextStyle(
                      fontSize: size.width * 0.04,
                      color: Colors.black,
                      fontWeight: FontWeight.w500,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(height: size.height * 0.01),
                  Expanded(
                    child: ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1, color: Colors.grey),
                      padding: isIpad
                          ? EdgeInsets.symmetric(vertical: size.width * 0.012)
                          : EdgeInsets.zero,
                      physics: const BouncingScrollPhysics(),
                      itemCount: purposeData.length,
                      itemBuilder: (ctx, int index) {
                        return ListTile(
                          contentPadding: isIpad
                              ? EdgeInsets.symmetric(
                                  vertical: size.width * 0.02,
                                )
                              : EdgeInsets.zero,
                          leading: Transform.scale(
                            scale: isIpad ? 1.8 : 1,
                            child: Checkbox(
                              visualDensity: VisualDensity.compact,
                              value: selectReason == purposeData[index],
                              onChanged: (value) {
                                setState(() {
                                  selectReason = purposeData[index];
                                });
                              },
                              activeColor: AppColors.primary,
                              checkColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4),
                              ),
                              side: const BorderSide(
                                color: Colors.grey,
                                width: 1.5,
                              ),
                            ),
                          ),
                          title: Text(
                            purposeData[index]['title']!,
                            style: TextStyle(
                              fontSize: size.width * 0.034,
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  Container(
                    width: double.infinity,
                    height: size.height * (isIpad ? 0.1 : 0.08),
                    padding: EdgeInsets.symmetric(
                      vertical: size.height * 0.015,
                    ),
                    child: state is SettingsLoading
                        ? const Center(child: CircularProgressIndicator())
                        : ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                  size.width * 0.03,
                                ),
                              ),
                            ),
                            onPressed: () {
                              if (selectReason.isNotEmpty) {
                                showDeleteDialog(
                                  size,
                                  context.read<SettingsBloc>(),
                                );
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                      "Please select reason...",
                                      style: TextStyle(
                                        fontFamily: 'AirbnbCereal',
                                      ),
                                    ),
                                  ),
                                );
                              }
                            },
                            child: Text(
                              'Delete Account',
                              style: TextStyle(
                                fontSize: size.width * (isIpad ? 0.032 : 0.038),
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  void showDeleteDialog(Size size, SettingsBloc bloc) {
    showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          contentPadding: EdgeInsets.zero,
          insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
          content: StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(size.width * 0.045),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Padding(
                      padding: EdgeInsets.only(left: size.width * 0.04),
                      child: Row(
                        children: [
                          Text(
                            "You'll be missed",
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: size.width * 0.05,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          const Spacer(),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: Icon(
                              Icons.close,
                              color: Colors.black,
                              size: size.width * 0.06,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                      ),
                      child: const Divider(color: Colors.black, thickness: 0.5),
                    ),
                    SizedBox(height: size.width * 0.02),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                      ),
                      child: Text(
                        "Are you sure you want to delete account? You will no longer be able to sell your pics or videos to the press, and earn money!",
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                    SizedBox(height: size.width * 0.04),
                    Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal: size.width * 0.04,
                        vertical: size.width * 0.04,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          Expanded(
                            child: SizedBox(
                              height: size.width * 0.12,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.black,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      size.width * 0.03,
                                    ),
                                  ),
                                ),
                                onPressed: () {
                                  Navigator.pop(dialogContext);
                                  bloc.add(DeleteAccount(selectReason));
                                },
                                child: const Text(
                                  "Proceed",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'AirbnbCereal',
                                  ),
                                ),
                              ),
                            ),
                          ),
                          SizedBox(width: size.width * 0.04),
                          Expanded(
                            child: SizedBox(
                              height: size.width * 0.12,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                      size.width * 0.03,
                                    ),
                                  ),
                                ),
                                onPressed: () => Navigator.pop(dialogContext),
                                child: const Text(
                                  "Cancel",
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontFamily: 'AirbnbCereal',
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}
