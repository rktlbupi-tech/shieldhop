import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:presshop_enterprise/features/notifications/data/services/enterprise_fcm_service.dart';

import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_icons.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutBack));
    _controller.forward();
    _navigate();
  }

  Future<void> _navigate() async {
    // LocalNotificationService.instance.showTestNotification();

    // Check if force update is required before routing forward
    // final isForceUpdateRequired =
    //     await ForceUpdateRepository.checkForceUpdate();
    // if (isForceUpdateRequired) {
    //   // Stay on the splash screen so the ForceUpdateWidget displays the popup here
    //   return;
    // }

    await Future.delayed(const Duration(milliseconds: 2200));
    if (!mounted) return;
    final prefs = await SharedPreferences.getInstance();
    final onboardingSeen = prefs.getBool('onboarding_seen') ?? false;
    final token = prefs.getString('auth_token');
    if (!mounted) return;
    if (!onboardingSeen) {
      context.go(AppRoutes.onboarding);
    } else if (token != null) {
      EnterpriseFcmService.registerToken();
      context.go(AppRoutes.dashboard);
    } else {
      context.go(AppRoutes.login);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      body: Center(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) => FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Image.asset(
                  AppIcons.logoWordmark,
                  width: 260.w,
                  errorBuilder: (ctx, e, st) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.business,
                        size: 80.sp,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'PRESSHOP',
                        style: TextStyle(
                          fontSize: 28.sp,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          fontFamily: 'AirbnbCereal',
                          letterSpacing: 4,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
