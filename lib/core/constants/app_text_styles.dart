import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

class AppTextStyles {
  AppTextStyles._();

  static double get _screenWidth {
    try {
      final view = ui.PlatformDispatcher.instance.views.first;
      final width = view.physicalSize.width / view.devicePixelRatio;

      return width.clamp(360.0, 440.0);
    } catch (_) {
      return 390.0;
    }
  }

  // ── Headings ─────────────────────────────────────────────
  static TextStyle get h1 => TextStyle(
    fontSize: _screenWidth * AppDimensions.numD072,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get h2 => TextStyle(
    fontSize: _screenWidth * AppDimensions.headerFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get h3 => TextStyle(
    fontSize: _screenWidth * AppDimensions.appBarHeadingFontSizeNew,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get h4 => TextStyle(
    fontSize: _screenWidth * AppDimensions.appBarHeadingFontSize,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  // ── Body ─────────────────────────────────────────────────
  static TextStyle get bodyLarge => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeLarge,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get bodyMedium => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );
  static TextStyle get bodyMedium2 => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeMedium2,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );
  static TextStyle get bodyMediumW400numD036 => TextStyle(
    fontSize: _screenWidth * AppDimensions.numD034,
    fontWeight: FontWeight.w500,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get bodySmall => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeSmall,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: 'AirbnbCereal',
  );

  // ── Label ────────────────────────────────────────────────
  static TextStyle get labelLarge => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get labelMedium => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeSmall,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get labelSmall => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeXS,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    fontFamily: 'AirbnbCereal',
  );

  // ── Button ───────────────────────────────────────────────
  static TextStyle get button => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeLarge,
    fontWeight: FontWeight.w600,
    color: AppColors.textOnPrimary,
    fontFamily: 'AirbnbCereal',
    letterSpacing: 0.5,
  );

  // ── Input ────────────────────────────────────────────────
  static TextStyle get input => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get inputHint => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeMedium,
    fontWeight: FontWeight.w400,
    color: AppColors.textHint,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get inputLabel => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeSmall,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: 'AirbnbCereal',
  );

  // ── Caption ──────────────────────────────────────────────
  static TextStyle get caption => TextStyle(
    fontSize: _screenWidth * AppDimensions.numD028,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
    fontFamily: 'AirbnbCereal',
  );

  static TextStyle get overline => TextStyle(
    fontSize: _screenWidth * AppDimensions.fontSizeXS,
    fontWeight: FontWeight.w500,
    color: AppColors.textHint,
    fontFamily: 'AirbnbCereal',
    letterSpacing: 1.2,
  );
}
