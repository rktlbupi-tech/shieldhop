import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/di/injection.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import '../../../../common/widgets/common_input_field.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>(),
      child: const _LoginView(),
    );
  }
}

class _LoginView extends StatefulWidget {
  const _LoginView();

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(BuildContext context) {
    if (_formKey.currentState!.validate()) {
      context.read<AuthBloc>().add(
        LoginSubmitted(_emailController.text.trim(), _passwordController.text),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go(AppRoutes.dashboard);
        } else if (state is AuthFailure) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text(state.message)));
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: EdgeInsets.symmetric(horizontal: 28.w),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 56.h),
                  // Brand logo, top-left (matches old EmployeeLoginScreen).
                  Image.asset(
                    AppIcons.logoWordmark,
                    width: 160.w,
                    errorBuilder: (ctx, e, st) => Icon(
                      Icons.business,
                      size: 56.sp,
                      color: AppColors.primary,
                    ),
                  ),
                  SizedBox(height: 22.h),
                  Text(
                    AppStrings.enterpriseLoginTitle,
                    style: AppTextStyles.h2.copyWith(height: 1.25),
                  ),
                  SizedBox(height: 6.h),
                  Text(
                    AppStrings.enterpriseLoginSubtitle,
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.5,
                    ),
                  ),
                  SizedBox(height: 36.h),
                  CommonInputField(
                    controller: _emailController,
                    label: AppStrings.email,
                    showLabel: false,
                    filled: false,
                    hint: AppStrings.officialEmailHint,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: Icons.email_outlined,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      return null;
                    },
                  ),
                  SizedBox(height: 18.h),
                  CommonInputField(
                    controller: _passwordController,
                    label: AppStrings.password,
                    showLabel: false,
                    filled: false,
                    hint: AppStrings.passwordHint,
                    isPassword: true,
                    prefixIcon: Icons.lock_outline,
                    validator: (v) {
                      if (v == null || v.isEmpty) {
                        return AppStrings.fieldRequired;
                      }
                      if (v.length < 8) return AppStrings.passwordTooShort;
                      return null;
                    },
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () => context.push(AppRoutes.forgotPassword),
                      child: Text(
                        AppStrings.forgotPassword,
                        style: AppTextStyles.labelMedium.copyWith(
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 20.h),
                  BlocBuilder<AuthBloc, AuthState>(
                    builder: (context, state) {
                      final isLoading = state is AuthLoading;
                      return SizedBox(
                        width: double.infinity,
                        height: 54.h,
                        child: ElevatedButton(
                          onPressed: isLoading ? null : () => _submit(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: AppColors.textOnPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14.r),
                            ),
                            elevation: 0,
                          ),
                          child: isLoading
                              ? SizedBox(
                                  height: 20.h,
                                  width: 20.w,
                                  child: const CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.textOnPrimary,
                                  ),
                                )
                              : Text(
                                  AppStrings.login.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 15.sp,
                                    fontWeight: FontWeight.w700,
                                    fontFamily: 'AirbnbCereal',
                                    letterSpacing: 0.5,
                                  ),
                                ),
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 22.h),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
