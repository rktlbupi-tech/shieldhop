import 'package:flutter/material.dart';

// ── Mode labels ──────────────────────────────────────────────────────────────
const String photoText = "Photo";
const String videoText = "Video";
const String audioText = "Audio";
const String scanText = "Scan";
const String interviewText = "Interview";
const String locationText = "Location";
const String timestampText = "Timestamp";
const String speakText = "Speak";
const String hashtagText = "Hashtag";
const String categoryText = "Category";
const String sharedText = "shared";
const String saveText = "save";
const String draftText = "draft";

// ── SharedPreferences keys ───────────────────────────────────────────────────
const String currentLat = "current_lat";
const String currentLon = "current_lon";
const String currentAddress = "current_address";
const String currentCountry = "current_country";
const String currentCity = "current_city";
const String currentState = "current_state";
const String contryCode = "country_code";

// ── Sizing constants (fraction of screen width) ──────────────────────────────
const double numD009 = 0.009;
const double numD01 = 0.01;
const double numD013 = 0.013;
const double numD015 = 0.015;
const double numD02 = 0.02;
const double numD022 = 0.022;
const double numD025 = 0.025;
const double numD026 = 0.026;
const double numD028 = 0.028;
const double numD03 = 0.03;
const double numD031 = 0.031;
const double numD032 = 0.032;
const double numD034 = 0.034;
const double numD035 = 0.035;
const double numD036 = 0.036;
const double numD038 = 0.038;
const double numD04 = 0.04;
const double numD042 = 0.042;
const double numD045 = 0.045;
const double numD05 = 0.05;
const double numD06 = 0.06;
const double numD07 = 0.07;
const double numD08 = 0.08;
const double numD09 = 0.09;
const double numD1 = 0.1;
const double numD11 = 0.11;
const double numD13 = 0.13;
const double numD15 = 0.15;
const double numD18 = 0.18;
const double numD22 = 0.22;
const double numD25 = 0.25;
const double numD28 = 0.28;
const double numD30 = 0.30;
const double numD32 = 0.32;
const double numD35 = 0.35;
const double numD45 = 0.45;

// ── Colors ───────────────────────────────────────────────────────────────────
const Color colorEmployeeGreen1 = Color(0xFF1877F2); // primary brand blue
const Color colorOnlineGreen = Color(0xFF388E3C);
const Color colorLightGrey = Color(0xFFF5F5F5);
const Color colorGreyNew = Color(0xFFE0E0E0);
const Color colorHint = Color(0xFFBDBDBD);
const Color colorTextFieldIcon = Color(0xFF757575);
const Color colorGoogleButtonBorder = Color(0xFFE0E0E0);
const Color appBarBg = Colors.white;

const double appBarHeadingFontSize = 0.045;

// ── Asset paths ───────────────────────────────────────────────────────────────
const String iconsPath = "assets/icons/";
const String imagesPath = "assets/images/";

// ── Helper style builders ─────────────────────────────────────────────────────

TextStyle commonTextStyle({
  required Size size,
  required double fontSize,
  required Color color,
  required FontWeight fontWeight,
}) {
  return TextStyle(
    fontSize: fontSize,
    color: color,
    fontWeight: fontWeight,
    fontFamily: 'AirbnbCereal',
  );
}

ButtonStyle commonButtonStyle(Size size, Color color) {
  return ElevatedButton.styleFrom(
    backgroundColor: color,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(size.width * numD03),
    ),
  );
}

TextStyle commonButtonTextStyle(Size size) {
  return commonTextStyle(
    size: size,
    fontSize: size.width * numD035,
    color: Colors.white,
    fontWeight: FontWeight.w700,
  );
}

Widget commonElevatedButton(
  String text,
  Size size,
  TextStyle textStyle,
  ButtonStyle buttonStyle,
  VoidCallback onPressed,
) {
  return SizedBox(
    width: double.infinity,
    child: ElevatedButton(
      style: buttonStyle,
      onPressed: onPressed,
      child: Text(text, style: textStyle),
    ),
  );
}

void showSnackBar(String title, String message, Color color) {
  final context = _scaffoldMessengerKey.currentContext;
  if (context == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: color,
      duration: const Duration(seconds: 2),
    ),
  );
}

void showToast(String message) {
  final context = _scaffoldMessengerKey.currentContext;
  if (context == null) return;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text(message), duration: const Duration(seconds: 2)),
  );
}

/// Key used by showSnackBar/showToast for scaffold-less contexts.
final GlobalKey<ScaffoldMessengerState> _scaffoldMessengerKey =
    GlobalKey<ScaffoldMessengerState>();
