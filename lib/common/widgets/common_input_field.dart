import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_text_styles.dart';

class CommonInputField extends StatefulWidget {
  final TextEditingController? controller;
  final String? label;
  final String? hint;
  final IconData? prefixIcon;
  final Widget? prefixWidget;
  final Widget? suffixIcon;
  final bool obscureText;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final bool filled;
  final bool showLabel;
  final bool showPrefixIcon;
  final bool showSuffixIcon;
  final void Function(String)? onChanged;
  final void Function(String)? onFieldSubmitted;
  final TextInputAction? textInputAction;
  final FocusNode? focusNode;
  final bool enabled;
  final int maxLines;
  final int? minLines;
  final AutovalidateMode? autovalidateMode;

  const CommonInputField({
    super.key,
    this.controller,
    this.label,
    this.hint,
    this.prefixIcon,
    this.prefixWidget,
    this.suffixIcon,
    this.obscureText = false,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.filled = true,
    this.showLabel = true,
    this.showPrefixIcon = true,
    this.showSuffixIcon = true,
    this.onChanged,
    this.onFieldSubmitted,
    this.textInputAction,
    this.focusNode,
    this.enabled = true,
    this.maxLines = 1,
    this.minLines,
    this.autovalidateMode,
  });

  @override
  State<CommonInputField> createState() => _CommonInputFieldState();
}

class _CommonInputFieldState extends State<CommonInputField> {
  late bool _obscureText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword ? true : widget.obscureText;
  }

  @override
  void didUpdateWidget(covariant CommonInputField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.isPassword != widget.isPassword || oldWidget.obscureText != widget.obscureText) {
      _obscureText = widget.isPassword ? true : widget.obscureText;
    }
  }

  @override
  Widget build(BuildContext context) {
    final OutlineInputBorder? outlined = widget.filled
        ? null
        : OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.r),
            borderSide: const BorderSide(color: AppColors.textFieldBorder),
          );

    Widget? buildPrefix() {
      if (!widget.showPrefixIcon) return null;
      if (widget.prefixWidget != null) return widget.prefixWidget;
      if (widget.prefixIcon != null) {
        return Icon(
          widget.prefixIcon,
          color: widget.filled ? AppColors.textSecondary : AppColors.textPrimary,
          size: 20.sp,
        );
      }
      if (widget.isPassword) {
        return Icon(
          Icons.lock_outline,
          color: widget.filled ? AppColors.textSecondary : AppColors.textPrimary,
          size: 20.sp,
        );
      }
      return null;
    }

    Widget? buildSuffix() {
      if (!widget.showSuffixIcon) return null;
      if (widget.suffixIcon != null) return widget.suffixIcon;
      if (widget.isPassword) {
        return IconButton(
          icon: Icon(
            _obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
            color: widget.filled ? AppColors.textSecondary : AppColors.textSecondary,
            size: 20.sp,
          ),
          onPressed: () {
            setState(() {
              _obscureText = !_obscureText;
            });
          },
        );
      }
      return null;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.showLabel && widget.label != null) ...[
          Text(widget.label!, style: AppTextStyles.inputLabel),
          SizedBox(height: 6.h),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscureText,
          keyboardType: widget.keyboardType,
          style: AppTextStyles.input,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onFieldSubmitted,
          textInputAction: widget.textInputAction,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          maxLines: widget.maxLines,
          minLines: widget.minLines,
          autovalidateMode: widget.autovalidateMode,
          decoration: InputDecoration(
            hintText: widget.hint,
            filled: widget.filled,
            fillColor: widget.filled ? null : Colors.transparent,
            prefixIcon: buildPrefix(),
            suffixIcon: buildSuffix(),
            border: outlined,
            enabledBorder: outlined,
            focusedBorder: widget.filled
                ? null
                : OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12.r),
                    borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
                  ),
          ),
        ),
      ],
    );
  }
}
