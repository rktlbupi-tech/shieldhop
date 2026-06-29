import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../../../../common/widgets/app_app_bar.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({
    super.key,
    required this.email,
    required this.otp,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _hidePassword = true;
  bool _hideConfirmPassword = true;
  bool _loading = false;

  // Requirement status states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasNumber = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _passwordCtrl.addListener(_validatePassword);
  }

  @override
  void dispose() {
    _passwordCtrl.removeListener(_validatePassword);
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  void _validatePassword() {
    final text = _passwordCtrl.text;
    setState(() {
      _hasMinLength = text.length >= 8;
      _hasUppercase = RegExp(r'[A-Z]').hasMatch(text);
      _hasLowercase = RegExp(r'[a-z]').hasMatch(text);
      _hasNumber = RegExp(r'[0-9]').hasMatch(text);
      _hasSpecialChar = RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(text);
    });
  }

  bool get _isPasswordValid =>
      _hasMinLength &&
      _hasUppercase &&
      _hasLowercase &&
      _hasNumber &&
      _hasSpecialChar;

  Future<void> _submit() async {
    if (!_isPasswordValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please meet all password requirements'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _loading = true);

    try {
      final response = await getIt<ApiClient>().post(
        ApiEndpoints.resetPassword,
        data: {
          'email': widget.email,
          'otp': widget.otp,
          'password': _passwordCtrl.text.trim(),
        },
      );

      final data = response.data as Map<String, dynamic>;
      if (response.statusCode == 200 ||
          data['code'] == 200 ||
          data['success'] == true) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
          // Pop twice to return back to Login Screen
          Navigator.pop(context);
          Navigator.pop(context);
        }
      } else {
        throw Exception(data['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      debugPrint('ResetPasswordError: $e');
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

  Widget _buildCheckRow(String label, bool isMet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4.h),
      child: Row(
        children: [
          Image.asset(
            isMet ? 'assets/icons/check.png' : 'assets/icons/cross.png',
            width: 14.w,
            height: 14.w,
          ),
          SizedBox(width: 8.w),
          Text(
            label,
            style: TextStyle(
              fontSize: 12.sp,
              fontFamily: 'AirbnbCereal',
              fontWeight: FontWeight.w500,
              color: isMet ? Colors.green : Colors.red,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: const AppAppBar(title: '', showBack: true, showLogo: false),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: EdgeInsets.symmetric(horizontal: 24.w),
            children: [
              SizedBox(height: 20.h),
              Text(
                'Reset Password',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AirbnbCereal',
                  fontSize: 26.sp,
                ),
              ),
              SizedBox(height: 8.h),
              Text(
                'Reset your password below to regain access to your account.',
                style: TextStyle(
                  color: Colors.black54,
                  fontSize: 14.sp,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              SizedBox(height: 28.h),

              // New Password Field
              TextFormField(
                controller: _passwordCtrl,
                obscureText: _hidePassword,
                decoration: InputDecoration(
                  hintText: 'Enter new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: InkWell(
                    onTap: () => setState(() => _hidePassword = !_hidePassword),
                    child: Icon(
                      _hidePassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  return null;
                },
              ),
              SizedBox(height: 16.h),

              // Checklist Section
              Text(
                'Minimum password requirement',
                style: TextStyle(
                  color: Colors.black,
                  fontSize: 13.sp,
                  fontWeight: FontWeight.w600,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              SizedBox(height: 8.h),
              _buildCheckRow(
                'Contains at least 01 lowercase character',
                _hasLowercase,
              ),
              _buildCheckRow(
                'Contains at least 01 special character',
                _hasSpecialChar,
              ),
              _buildCheckRow(
                'Contains at least 01 uppercase character',
                _hasUppercase,
              ),
              _buildCheckRow('Must be at least 08 characters', _hasMinLength),
              _buildCheckRow('Contains at least 01 number', _hasNumber),
              SizedBox(height: 24.h),

              // Confirm Password Field
              TextFormField(
                controller: _confirmPasswordCtrl,
                obscureText: _hideConfirmPassword,
                decoration: InputDecoration(
                  hintText: 'Confirm new password',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: InkWell(
                    onTap: () => setState(
                      () => _hideConfirmPassword = !_hideConfirmPassword,
                    ),
                    child: Icon(
                      _hideConfirmPassword
                          ? Icons.visibility_off_outlined
                          : Icons.visibility_outlined,
                      color: Colors.black54,
                    ),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.isEmpty)
                    return 'Confirm password is required';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              SizedBox(height: 40.h),

              // Submit Button
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
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          'Submit',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                ),
              ),
              SizedBox(height: 20.h),

              // Back to Sign In Link
              Center(
                child: TextButton(
                  onPressed: () {
                    // Pop twice to return back to Login Screen
                    Navigator.pop(context);
                    Navigator.pop(context);
                  },
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
            ],
          ),
        ),
      ),
    );
  }
}
