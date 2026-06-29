import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onButtonTap;

  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onButtonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(32.r),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64.sp,
                color: AppColors.textHint),
            SizedBox(height: 16.h),
            Text(title,
                textAlign: TextAlign.center,
                style: AppTextStyles.h4
                    .copyWith(color: AppColors.textSecondary)),
            if (subtitle != null) ...[
              SizedBox(height: 8.h),
              Text(subtitle!,
                  textAlign: TextAlign.center,
                  style: AppTextStyles.bodySmall),
            ],
            if (buttonLabel != null && onButtonTap != null) ...[
              SizedBox(height: 24.h),
              ElevatedButton(
                  onPressed: onButtonTap,
                  child: Text(buttonLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}
