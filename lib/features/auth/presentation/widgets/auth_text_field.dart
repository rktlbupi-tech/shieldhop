import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

class AuthTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;

  /// When false, the field renders as a transparent, outlined field with a
  /// grey border (the employee-login look from the old app). Defaults to the
  /// app's filled theme so existing screens are unaffected.
  final bool filled;

  /// Hides the floating label and renders it via the field's [hint] instead —
  /// used by the employee login layout which shows no separate label.
  final bool showLabel;

  const AuthTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.hint,
    required this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.filled = true,
    this.showLabel = true,
  });

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder? outlined = filled
        ? null
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.textFieldBorder),
          );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showLabel) ...[
          Text(label, style: AppTextStyles.inputLabel),
          SizedBox(height: 6.h),
        ],
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          style: AppTextStyles.input,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            filled: filled,
            fillColor: filled ? null : Colors.transparent,
            prefixIcon: Icon(
              prefixIcon,
              color: filled ? AppColors.textSecondary : AppColors.textPrimary,
              size: 20.sp,
            ),
            suffixIcon: suffixIcon,
            border: outlined,
            enabledBorder: outlined,
            focusedBorder: filled
                ? null
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide:
                        const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
          ),
        ),
      ],
    );
  }
}
