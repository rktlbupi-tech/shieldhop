import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../config/di/injection.dart';
import '../../config/routes/app_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../features/dashboard/presentation/screens/dashboard_screen.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';

class CompanyLogoWidget extends StatelessWidget {
  final double? size;

  const CompanyLogoWidget({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    String? logoUrl;

    try {
      final state = BlocProvider.of<ProfileBloc>(context, listen: false).state;
      if (state is ProfileLoaded) logoUrl = state.profile.companyLogo;
    } catch (_) {}

    if (logoUrl == null || logoUrl.isEmpty) {
      final prefs = getIt<SharedPreferences>();
      logoUrl = prefs.getString('company_logo');
    }

    final s = size ?? 38.w;
    final hasLogo = logoUrl != null && logoUrl.isNotEmpty;

    return GestureDetector(
      onTap: () => goToDashboardHome(context),
      child: Container(
        width: s,
        height: s,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.grey.shade100,
          border: Border.all(color: Colors.grey.shade400, width: 1.5),
          image: hasLogo
              ? DecorationImage(image: NetworkImage(logoUrl), fit: BoxFit.cover)
              : null,
        ),
        child: hasLogo
            ? null
            : ClipOval(
                child: Image.asset(
                  AppIcons.appLogo,
                  fit: BoxFit.contain,
                  errorBuilder: (_, e, s) => Icon(
                    Icons.business,
                    color: AppColors.primary,
                    size: (size ?? 38.w) * 0.5,
                  ),
                ),
              ),
      ),
    );
  }
}

/// Tapping the company logo always lands the user on the dashboard Home tab.
///
/// - If we're already inside the dashboard (e.g. on the Evidence/Tasks/Team/Menu
///   tab), switch the active tab back to Home (index 2) without re-navigating —
///   `context.go(dashboard)` would be a no-op there since the route is unchanged.
/// - Otherwise (on a separate pushed screen), navigate to the dashboard, which
///   builds with Home as the initial tab.
void goToDashboardHome(BuildContext context) {
  final dashboardState = context
      .findAncestorStateOfType<DashboardScreenState>();
  if (dashboardState != null) {
    dashboardState.changeTab(2);
  } else {
    // The dashboard may already be alive underneath this pushed screen on a
    // different tab. A plain go('/dashboard') would reuse that state and keep
    // the old tab, so we pass a one-shot token (`ts`) that forces the Home
    // tab (index 2) once the dashboard rebuilds.
    final token = DateTime.now().microsecondsSinceEpoch;
    context.go('${AppRoutes.dashboard}?tab=2&ts=$token');
  }
}

/// Convenience padding wrapper to drop into AppBar.actions lists.
class CompanyLogoAction extends StatelessWidget {
  final double? size;

  const CompanyLogoAction({super.key, this.size});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(right: 12.w),
      child: Center(child: CompanyLogoWidget(size: size)),
    );
  }
}
