import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';
import 'company_logo_widget.dart';

class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String? title;
  final Widget? titleWidget;
  final List<Widget>? actions;
  final Widget? leading;
  final bool showBack;
  final Color? backgroundColor;
  final bool centerTitle;
  final double? titleSpacing;
  final double? elevation;
  final bool showLogo;
  final VoidCallback? onBackTap;

  const AppAppBar({
    super.key,
    this.title,
    this.titleWidget,
    this.actions,
    this.leading,
    this.showBack = false,
    this.backgroundColor,
    this.centerTitle = false,
    this.titleSpacing,
    this.elevation,
    this.showLogo = true,
    this.onBackTap,
  });

  @override
  Widget build(BuildContext context) {
    return AppBar(
      scrolledUnderElevation: 0,
      backgroundColor: backgroundColor ?? Colors.white,
      elevation: elevation ?? 0.5,
      centerTitle: centerTitle,
      titleSpacing: titleSpacing ?? 0,
      automaticallyImplyLeading: showBack,
      leading:
          leading ??
          (showBack
              ? IconButton(
                  icon: Image.asset(
                    'assets/icons/ic_arrow_left.png',
                    width: 24.w,
                    height: 24.w,
                    color: AppColors.textPrimary,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.arrow_back_ios_new,
                        size: 22.sp,
                        color: AppColors.textPrimary,
                      );
                    },
                  ),
                  onPressed: onBackTap ?? () => Navigator.pop(context),
                )
              : null),
      title:
          titleWidget ??
          (title != null
              ? Text(
                  title!,
                  style: AppTextStyles.h4.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AirbnbCereal',
                  ),
                )
              : null),
      actions: [...?actions, if (showLogo) const CompanyLogoAction()],
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(56.h);
}
