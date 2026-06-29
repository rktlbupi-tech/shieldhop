import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

/// Lightweight placeholder for employee pages that are scaffolded but not yet
/// fully ported from the old app.
class ComingSoonScreen extends StatelessWidget {
  final String title;
  final IconData icon;

  const ComingSoonScreen({
    super.key,
    required this.title,
    this.icon = Icons.construction_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        title: Text(title),
        backgroundColor: AppColors.surface,
        foregroundColor: AppColors.textPrimary,
        elevation: 0.5,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(24.r),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 56.sp, color: AppColors.primary),
            ),
            SizedBox(height: 20.h),
            Text(title, style: AppTextStyles.h3),
            SizedBox(height: 8.h),
            Text('Coming soon',
                style: AppTextStyles.bodyMedium
                    .copyWith(color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}
