import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

class Responsive {
  Responsive._();

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;

  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1024;

  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1024;

  static double screenWidth(BuildContext context) =>
      MediaQuery.of(context).size.width;

  static double screenHeight(BuildContext context) =>
      MediaQuery.of(context).size.height;
}

// Spacing constants using ScreenUtil
class AppSpacing {
  AppSpacing._();

  static double get xs => 4.h;
  static double get sm => 8.h;
  static double get md => 12.h;
  static double get lg => 16.h;
  static double get xl => 20.h;
  static double get xxl => 24.h;
  static double get xxxl => 32.h;

  static SizedBox get gapXS => SizedBox(height: xs);
  static SizedBox get gapSM => SizedBox(height: sm);
  static SizedBox get gapMD => SizedBox(height: md);
  static SizedBox get gapLG => SizedBox(height: lg);
  static SizedBox get gapXL => SizedBox(height: xl);
  static SizedBox get gapXXL => SizedBox(height: xxl);

  static SizedBox get hGapXS => SizedBox(width: xs);
  static SizedBox get hGapSM => SizedBox(width: sm);
  static SizedBox get hGapMD => SizedBox(width: md);
  static SizedBox get hGapLG => SizedBox(width: lg);
  static SizedBox get hGapXL => SizedBox(width: xl);
}

class AppRadius {
  AppRadius._();

  static double get sm => 8.r;
  static double get md => 12.r;
  static double get lg => 16.r;
  static double get xl => 24.r;
  static double get full => 100.r;
}

class AppPadding {
  AppPadding._();

  static EdgeInsets get screenH =>
      EdgeInsets.symmetric(horizontal: 20.w);

  static EdgeInsets get screenAll =>
      EdgeInsets.symmetric(horizontal: 20.w, vertical: 20.h);

  static EdgeInsets get cardAll =>
      EdgeInsets.all(16.r);

  static EdgeInsets get buttonV =>
      EdgeInsets.symmetric(vertical: 14.h);
}
