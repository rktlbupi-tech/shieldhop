// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';
// import 'package:flutter_screenutil/flutter_screenutil.dart';
// import 'package:go_router/go_router.dart';
// import '../../../../config/di/injection.dart';
// import '../../../../config/routes/app_router.dart';
// import '../../../../core/constants/app_colors.dart';
// import '../../../../core/constants/app_strings.dart';
// import '../../../../core/constants/app_text_styles.dart';
// import '../bloc/auth_bloc.dart';
// import '../bloc/auth_event.dart';
// import '../bloc/auth_state.dart';
// import '../widgets/auth_text_field.dart';

// class SignupScreen extends StatelessWidget {
//   const SignupScreen({super.key});

//   @override
//   Widget build(BuildContext context) {
//     return BlocProvider(
//       create: (_) => getIt<AuthBloc>(),
//       child: const _SignupView(),
//     );
//   }
// }

// class _SignupView extends StatefulWidget {
//   const _SignupView();
//   @override State<_SignupView> createState() => _SignupViewState();
// }

// class _SignupViewState extends State<_SignupView> {
//   final _formKey = GlobalKey<FormState>();
//   final _nameController = TextEditingController();
//   final _emailController = TextEditingController();
//   final _passwordController = TextEditingController();
//   final _confirmPasswordController = TextEditingController();
//   bool _obscurePassword = true;
//   bool _obscureConfirm = true;

//   @override
//   void dispose() {
//     _nameController.dispose();
//     _emailController.dispose();
//     _passwordController.dispose();
//     _confirmPasswordController.dispose();
//     super.dispose();
//   }

//   void _submit(BuildContext context) {
//     if (_formKey.currentState?.validate() ?? false) {
//       context.read<AuthBloc>().add(SignupSubmitted(
//         _nameController.text.trim(),
//         _emailController.text.trim(),
//         _passwordController.text,
//       ));
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return BlocListener<AuthBloc, AuthState>(
//       listener: (context, state) {
//         if (state is AuthAuthenticated) {
//           context.go(AppRoutes.dashboard);
//         } else if (state is AuthFailure) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text(state.message), backgroundColor: AppColors.error),
//           );
//         }
//       },
//       child: Scaffold(
//         backgroundColor: AppColors.background,
//         appBar: AppBar(
//           backgroundColor: AppColors.transparent,
//           elevation: 0,
//           leading: IconButton(
//             icon: Icon(Icons.arrow_back_ios, color: AppColors.textPrimary, size: 20.sp),
//             onPressed: () => Navigator.pop(context),
//           ),
//         ),
//         body: SafeArea(
//           child: SingleChildScrollView(
//             padding: EdgeInsets.symmetric(horizontal: 24.w),
//             child: Form(
//               key: _formKey,
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   SizedBox(height: 12.h),
//                   Text(AppStrings.createAccount, style: AppTextStyles.h2),
//                   SizedBox(height: 4.h),
//                   Text(AppStrings.signupSubtitle,
//                       style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary)),
//                   SizedBox(height: 32.h),
//                   AuthTextField(
//                     controller: _nameController,
//                     label: AppStrings.fullName,
//                     hint: 'John Doe',
//                     prefixIcon: Icons.person_outline,
//                     validator: (v) => (v == null || v.isEmpty) ? AppStrings.fieldRequired : null,
//                   ),
//                   SizedBox(height: 16.h),
//                   AuthTextField(
//                     controller: _emailController,
//                     label: AppStrings.email,
//                     hint: 'you@company.com',
//                     keyboardType: TextInputType.emailAddress,
//                     prefixIcon: Icons.email_outlined,
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return AppStrings.fieldRequired;
//                       if (!v.contains('@')) return AppStrings.invalidEmail;
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16.h),
//                   AuthTextField(
//                     controller: _passwordController,
//                     label: AppStrings.password,
//                     hint: '••••••••',
//                     obscureText: _obscurePassword,
//                     prefixIcon: Icons.lock_outline,
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                         color: AppColors.textSecondary, size: 20.sp,
//                       ),
//                       onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return AppStrings.fieldRequired;
//                       if (v.length < 8) return AppStrings.passwordTooShort;
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 16.h),
//                   AuthTextField(
//                     controller: _confirmPasswordController,
//                     label: AppStrings.confirmPassword,
//                     hint: '••••••••',
//                     obscureText: _obscureConfirm,
//                     prefixIcon: Icons.lock_outline,
//                     suffixIcon: IconButton(
//                       icon: Icon(
//                         _obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined,
//                         color: AppColors.textSecondary, size: 20.sp,
//                       ),
//                       onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
//                     ),
//                     validator: (v) {
//                       if (v == null || v.isEmpty) return AppStrings.fieldRequired;
//                       if (v != _passwordController.text) return AppStrings.passwordsDoNotMatch;
//                       return null;
//                     },
//                   ),
//                   SizedBox(height: 32.h),
//                   BlocBuilder<AuthBloc, AuthState>(
//                     builder: (context, state) {
//                       final isLoading = state is AuthLoading;
//                       return ElevatedButton(
//                         onPressed: isLoading ? null : () => _submit(context),
//                         child: isLoading
//                             ? SizedBox(height: 20.h, width: 20.w,
//                                 child: const CircularProgressIndicator(strokeWidth: 2, color: AppColors.textOnPrimary))
//                             : const Text(AppStrings.signup),
//                       );
//                     },
//                   ),
//                   SizedBox(height: 24.h),
//                   Center(
//                     child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
//                       Text(AppStrings.alreadyHaveAccount, style: AppTextStyles.bodySmall),
//                       GestureDetector(
//                         onTap: () => Navigator.pop(context),
//                         child: Text(AppStrings.loginHere,
//                             style: AppTextStyles.bodySmall.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
//                       ),
//                     ]),
//                   ),
//                   SizedBox(height: 32.h),
//                 ],
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
