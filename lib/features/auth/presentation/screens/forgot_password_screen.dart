import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:otp_pin_field/otp_pin_field.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../common/widgets/app_app_bar.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _loading = true);

    final email = _emailCtrl.text.trim();

    try {
      final response = await getIt<ApiClient>().post(
        ApiEndpoints.forgotPassword,
        data: {'email': email},
      );

      final data = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 ||
          data['code'] == 200 ||
          data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('OTP sent to your email address'),
              backgroundColor: Colors.green,
            ),
          );
          _showOtpBottomSheet(email);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to send OTP');
      }
    } catch (e) {
      debugPrint('ForgotPasswordError: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception:', '').trim()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showOtpBottomSheet(String email) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25.r)),
      ),
      builder: (bottomSheetContext) {
        return OtpBottomSheet(
          email: email,
          onVerify: (emailAddress, otpCode) =>
              _verifyOtp(bottomSheetContext, emailAddress, otpCode),
          onResend: () async {
            Navigator.pop(bottomSheetContext);
            await _submit();
          },
        );
      },
    );
  }

  Future<void> _verifyOtp(
    BuildContext bottomSheetContext,
    String email,
    String otp,
  ) async {
    final bottomSheetNavigator = Navigator.of(bottomSheetContext);
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    try {
      final response = await getIt<ApiClient>().post(
        ApiEndpoints.verifyOtp,
        data: {'email': email, 'otp': otp},
      );

      final data = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 ||
          data['otp_match'] == true ||
          data['success'] == true) {
        // Close OTP Bottom Sheet
        bottomSheetNavigator.pop();
        // Navigate to ResetPasswordScreen
        if (context.mounted) {
          context.push(
            AppRoutes.resetPassword,
            extra: {'email': email, 'otp': otp},
          );
        }
      } else {
        throw Exception(data['message'] ?? 'Invalid OTP code');
      }
    } catch (e) {
      debugPrint('VerifyOtpError: $e');
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception:', '').trim()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.white,
      appBar: const AppAppBar(title: '', showBack: true, showLogo: false),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(height: 24.h),
                Text(
                  'Forgot Password',
                  style: TextStyle(
                    fontSize: 26.sp,
                    fontWeight: FontWeight.w600,
                    fontFamily: 'AirbnbCereal',
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 8.h),
                Text(
                  "Don't worry, it happens to all of us! Please enter your registered email address to reset your password",
                  style: TextStyle(
                    fontSize: 14.sp,
                    fontFamily: 'AirbnbCereal',
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                SizedBox(height: 36.h),
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Enter email address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter a valid email';
                    return null;
                  },
                ),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _loading
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.textOnPrimary,
                            ),
                          )
                        : const Text(
                            'Submit',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 8.h),
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Sign In',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 8.h),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class OtpBottomSheet extends StatefulWidget {
  final String email;
  final Function(String, String) onVerify;
  final VoidCallback onResend;

  const OtpBottomSheet({
    super.key,
    required this.email,
    required this.onVerify,
    required this.onResend,
  });

  @override
  State<OtpBottomSheet> createState() => _OtpBottomSheetState();
}

class _OtpBottomSheetState extends State<OtpBottomSheet> {
  int _secondsLeft = 300;
  Timer? _timer;
  final _otpPinController = GlobalKey<OtpPinFieldState>();
  bool _verifying = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_secondsLeft > 0) {
        if (mounted) {
          setState(() {
            _secondsLeft--;
          });
        }
      } else {
        _timer?.cancel();
        if (mounted) {
          setState(() {});
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final minutes = (_secondsLeft ~/ 60).toString().padLeft(2, '0');
    final seconds = (_secondsLeft % 60).toString().padLeft(2, '0');
    final expireTimeValue = "$minutes:$seconds";

    return PopScope(
      canPop: false, // Prevent back button dismissing
      child: Stack(
        children: [
          Padding(
            padding: EdgeInsets.all(8.r),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.black54),
                  onPressed: () {
                    Navigator.pop(context);
                  },
                ),
              ],
            ),
          ),
          Padding(
            padding: EdgeInsets.only(
              left: 24.w,
              right: 24.w,
              top: 24.h,
              bottom: MediaQuery.of(context).viewInsets.bottom + 20.h,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(height: 20.h),
                Text(
                  "Verify OTP",
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 22.sp,
                    fontWeight: FontWeight.w700,
                    color: Colors.black,
                  ),
                ),
                SizedBox(height: 12.h),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    children: [
                      TextSpan(
                        text: "We’ve sent a 5-digit verification code to ",
                        style: TextStyle(
                          color: Colors.black54,
                          fontSize: 14.sp,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      TextSpan(
                        text: widget.email,
                        style: TextStyle(
                          color: AppColors.primary,
                          fontFamily: 'AirbnbCereal',
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 32.h),
                OtpPinField(
                  key: _otpPinController,
                  onSubmit: (pin) => debugPrint("Entered OTP: $pin"),
                  onChange: (pin) => debugPrint("OTP Changed: $pin"),
                  otpPinFieldStyle: OtpPinFieldStyle(
                    defaultFieldBorderColor: AppColors.textFieldBorder,
                    activeFieldBorderColor: const Color(0xFF505050),
                    defaultFieldBackgroundColor: const Color(0xFFF3F5F4),
                    activeFieldBackgroundColor: const Color(0xFFF3F5F4),
                    fieldBorderRadius: 8.r,
                    fieldBorderWidth: 0.5,
                  ),
                  maxLength: 5,
                  showCursor: true,
                  cursorColor: const Color(0xFF505050),
                  showCustomKeyboard: false,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  otpPinFieldDecoration: OtpPinFieldDecoration.custom,
                ),
                SizedBox(height: 36.h),
                SizedBox(
                  width: double.infinity,
                  height: 52.h,
                  child: ElevatedButton(
                    onPressed: _verifying
                        ? null
                        : () async {
                            final otpValue =
                                _otpPinController
                                    .currentState
                                    ?.controller
                                    .text ??
                                "";
                            if (otpValue.isEmpty || otpValue.length < 5) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Please enter the 5-digit OTP"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                              return;
                            }
                            setState(() => _verifying = true);
                            await widget.onVerify(widget.email, otpValue);
                            if (mounted) setState(() => _verifying = false);
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: AppColors.textOnPrimary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.r),
                      ),
                      elevation: 0,
                    ),
                    child: _verifying
                        ? SizedBox(
                            height: 20.h,
                            width: 20.w,
                            child: const CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            "Verify OTP",
                            style: TextStyle(
                              fontSize: 14.sp,
                              color: Colors.white,
                              fontFamily: 'AirbnbCereal',
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 24.h),
                if (_secondsLeft != 0)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.asset(
                        "assets/icons/ic_time.png",
                        height: 20.w,
                        width: 20.w,
                      ),
                      SizedBox(width: 8.w),
                      Text(
                        "OTP will expire in $expireTimeValue Min",
                        style: TextStyle(
                          fontFamily: 'AirbnbCereal',
                          color: Colors.black,
                          fontSize: 14.sp,
                        ),
                      ),
                    ],
                  ),
                if (_secondsLeft == 0)
                  TextButton(
                    onPressed: widget.onResend,
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        children: [
                          TextSpan(
                            text: "Didn't receive code? ",
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              color: Colors.black54,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextSpan(
                            text: "Click here",
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              color: AppColors.primary,
                              fontWeight: FontWeight.bold,
                              fontSize: 14.sp,
                            ),
                          ),
                          TextSpan(
                            text: " to get another one",
                            style: TextStyle(
                              fontFamily: 'AirbnbCereal',
                              color: Colors.black54,
                              fontSize: 14.sp,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                SizedBox(height: 12.h),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
