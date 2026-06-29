import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../constants/app_colors.dart';

class AppTheme {
  AppTheme._();

  static ThemeData get light => ThemeData(
        useMaterial3: true,
        fontFamily: 'AirbnbCereal', // fallback: system font if AirbnbCereal assets not added
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.primary,
          primary: AppColors.primary,
          onPrimary: AppColors.textOnPrimary,
          secondary: AppColors.accent,
          onSecondary: AppColors.textOnAccent,
          surface: AppColors.surface,
          error: AppColors.error,
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: AppColors.background,
        primaryColor: AppColors.primary,
        dividerColor: AppColors.divider,

        // AppBar
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.white,
          foregroundColor: Colors.black87,
          elevation: 0.5,
          centerTitle: true,
          titleTextStyle: TextStyle(
            fontSize: 18.sp,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            fontFamily: 'AirbnbCereal',
          ),
          iconTheme: const IconThemeData(color: Colors.black87),
        ),

        // Elevated Button
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: AppColors.textOnPrimary,
            minimumSize: Size(double.infinity, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            textStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'AirbnbCereal',
            ),
            elevation: 0,
          ),
        ),

        // Outlined Button
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: Size(double.infinity, 52.h),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12.r),
            ),
            side: const BorderSide(color: AppColors.primary, width: 1.5),
            textStyle: TextStyle(
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ),

        // Input / TextField
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: AppColors.surface,
          contentPadding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.border),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.error),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.error, width: 1.5),
          ),
          hintStyle: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textHint,
            fontFamily: 'AirbnbCereal',
          ),
          labelStyle: TextStyle(
            fontSize: 14.sp,
            color: AppColors.textSecondary,
            fontFamily: 'AirbnbCereal',
          ),
          errorStyle: TextStyle(
            fontSize: 11.sp,
            color: AppColors.error,
            fontFamily: 'AirbnbCereal',
          ),
        ),

        // Card
        cardTheme: CardThemeData(
          color: AppColors.cardBackground,
          elevation: 2,
          shadowColor: Colors.black12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12.r),
          ),
          margin: EdgeInsets.zero,
        ),

        // Checkbox
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.primary;
            return AppColors.transparent;
          }),
          side: const BorderSide(color: AppColors.border, width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4.r)),
        ),

        // Divider
        dividerTheme: const DividerThemeData(
          color: AppColors.divider,
          thickness: 1,
          space: 0,
        ),

        // SnackBar
        snackBarTheme: SnackBarThemeData(
          backgroundColor: AppColors.textPrimary,
          contentTextStyle: TextStyle(
            fontSize: 14.sp,
            color: Colors.white,
            fontFamily: 'AirbnbCereal',
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.r)),
          behavior: SnackBarBehavior.floating,
        ),
      );
}
