import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/di/injection.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_icons.dart';
import '../../features/profile/presentation/bloc/profile_bloc.dart';
import '../../features/profile/domain/entities/profile_entity.dart';
import 'company_logo_widget.dart';

/// Shared dashboard top bar — port of the old app's [EmployeeDashboardAppBar].
/// Left: circular avatar with an online dot, employee name, media house.
/// Right: company logo. Tapping the left cluster can open the profile.
class EmployeeAppBar extends StatelessWidget implements PreferredSizeWidget {
  final bool isOnline;
  final VoidCallback? onProfileTap;
  final VoidCallback? onFilterTap;
  final VoidCallback? onBackTap;
  final String? firstNameOverride;
  final String? lastNameOverride;
  final String? companyNameOverride;
  final String? avatarOverride;
  final String? companyLogoOverride;

  const EmployeeAppBar({
    super.key,
    this.isOnline = true,
    this.onProfileTap,
    this.onFilterTap,
    this.onBackTap,
    this.firstNameOverride,
    this.lastNameOverride,
    this.companyNameOverride,
    this.avatarOverride,
    this.companyLogoOverride,
  });

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    ProfileBloc? bloc;
    try {
      bloc = BlocProvider.of<ProfileBloc>(context);
    } catch (_) {}

    if (bloc != null) {
      return BlocBuilder<ProfileBloc, ProfileState>(
        bloc: bloc,
        buildWhen: (prev, curr) =>
            curr is ProfileLoaded || curr is ProfileLoading,
        builder: (context, state) {
          final profile = state is ProfileLoaded ? state.profile : null;
          return _buildWithProfile(context, profile);
        },
      );
    } else {
      return _buildWithProfile(context, null);
    }
  }

  Widget _buildWithProfile(BuildContext context, ProfileEntity? profile) {
    final prefs = getIt<SharedPreferences>();
    final firstName =
        firstNameOverride ??
        profile?.firstName ??
        prefs.getString('user_first_name') ??
        'Employee';
    final lastName =
        lastNameOverride ??
        profile?.lastName ??
        prefs.getString('user_last_name') ??
        '';
    final fullName = '$firstName $lastName'.trim();
    final mediaHouse =
        companyNameOverride ??
        profile?.companyName ??
        prefs.getString('company_name') ??
        'Shieldhop';
    final avatar =
        avatarOverride ??
        profile?.profileImage ??
        prefs.getString('user_avatar');
    final companyLogo =
        companyLogoOverride ??
        profile?.companyLogo ??
        prefs.getString('company_logo');

    return AppBar(
      backgroundColor: AppColors.surface,
      elevation: 0.5,
      scrolledUnderElevation: 0,
      shadowColor: Colors.black.withValues(alpha: 0.1),
      automaticallyImplyLeading: false,
      leading: onBackTap != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              onPressed: onBackTap,
            )
          : null,
      titleSpacing: 0,
      title: Padding(
        padding: EdgeInsets.only(
          left: onBackTap != null ? 0 : 16.w,
          right: 16.w,
        ),
        child: Row(
          children: [
            Expanded(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: onProfileTap,
                child: Row(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 42.w,
                          height: 42.w,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: Colors.grey.shade100,
                            border: Border.all(
                              color: Colors.grey.shade400,
                              width: 1.5,
                            ),
                            image: (avatar != null && avatar.isNotEmpty)
                                ? DecorationImage(
                                    image: NetworkImage(avatar),
                                    fit: BoxFit.cover,
                                  )
                                : null,
                          ),
                          child: (avatar == null || avatar.isEmpty)
                              ? Icon(
                                  Icons.person,
                                  color: Colors.grey.shade500,
                                  size: 24.sp,
                                )
                              : null,
                        ),
                        Positioned(
                          right: 0,
                          top: 0,
                          child: Container(
                            width: 11.w,
                            height: 11.w,
                            decoration: BoxDecoration(
                              color: isOnline
                                  ? AppColors.accent
                                  : Colors.grey.shade400,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1.5,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black87,
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          Text(
                            mediaHouse,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: Colors.black54,
                              fontSize: 11.sp,
                              fontWeight: FontWeight.w400,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            if (onFilterTap != null)
              IconButton(
                onPressed: onFilterTap,
                icon: Image.asset(
                  'assets/icons/filter_new.png',
                  width: 22.sp,
                  height: 22.sp,
                  fit: BoxFit.contain,
                ),
              ),
            GestureDetector(
              onTap: () => goToDashboardHome(context),
              child: Container(
                height: 42.w,
                width: 42.w,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white,
                  // Matches the avatar's grey ring + size on the left.
                  border: Border.all(color: Colors.grey.shade400, width: 1.5),
                  image: (companyLogo != null && companyLogo.isNotEmpty)
                      ? DecorationImage(
                          image: NetworkImage(companyLogo),
                          fit: BoxFit.cover,
                        )
                      : null,
                ),
                child: (companyLogo == null || companyLogo.isEmpty)
                    ? Padding(
                        padding: EdgeInsets.all(6.w),
                        child: Image.asset(
                          AppIcons.appLogo,
                          fit: BoxFit.contain,
                          errorBuilder: (ctx, e, st) => Icon(
                            Icons.business,
                            color: AppColors.primary,
                            size: 20.sp,
                          ),
                        ),
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
