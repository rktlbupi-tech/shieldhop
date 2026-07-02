import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/features/notifications/data/services/enterprise_fcm_service.dart';
import 'package:flutter_switch/flutter_switch.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/injection.dart';
import '../../../../config/routes/app_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../common/widgets/employee_app_bar.dart';

import '../../../dashboard/presentation/screens/dashboard_screen.dart';
import '../../../app_settings/presentation/cubit/app_settings_cubit.dart';

const _iconsPath = 'assets/icons/';
const Color colorLightGrey = Color(0xFFF3F5F4);

class MenuScreen extends StatefulWidget {
  const MenuScreen({super.key});

  @override
  State<MenuScreen> createState() => _MenuScreenState();
}

// 9792728283
class _MenuScreenState extends State<MenuScreen> {
  bool _onDuty = false;
  int _notificationCount = 0;

  void _open(String path, {Object? extra}) {
    context.push(path, extra: extra);
  }

  /// Confirmation shown when the employee tries to go OFF duty — ported from
  /// the old app's `_showStopServiceConfirmationNew` (employee variant).
  void _showGoOffDutyDialog() {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size.width * 0.045),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(left: size.width * 0.04),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        "Go Off Duty?",
                        style: AppTextStyles.h3.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: size.width * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: const Divider(color: Colors.black, thickness: 0.5),
              ),
              SizedBox(height: size.width * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size.width * 0.04),
                        border: Border.all(color: Colors.black),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(size.width * 0.04),
                        child: Image.asset(
                          "assets/rabbits/locationoffpopemployee.png",
                          height: size.width * 0.30,
                          width: size.width * 0.35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Text(
                        "Going offline disables live tracking and visibility for your newsroom and nearby colleagues. For your safety, please remain online whilst on duty.",
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width * 0.035,
                          fontWeight: FontWeight.w500,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.width * 0.04,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: size.width * 0.12,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.pop(ctx);
                            setState(() => _onDuty = false);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                            ),
                          ),
                          child: const Text(
                            "Go Off Duty",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: SizedBox(
                        height: size.width * 0.12,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(ctx),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.employeeBlue,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                            ),
                          ),
                          child: const Text(
                            "Stay Online",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _logout() async {
    final prefs = getIt<SharedPreferences>();
    await EnterpriseFcmService.removeToken();
    await prefs.remove('auth_token');
    await prefs.remove('user_id');
    await prefs.remove('user_email');
    await prefs.remove('user_first_name');
    await prefs.remove('user_last_name');
    await prefs.remove('user_phone');
    await prefs.remove('user_avatar');
    await prefs.remove('user_role');
    await prefs.remove('company_name');
    await prefs.remove('company_logo');
    await prefs.remove('onboarding_seen');
    if (!mounted) return;
    context.go(AppRoutes.onboarding);
  }

  void _logoutDialog() {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        contentPadding: EdgeInsets.zero,
        insetPadding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
        content: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(size.width * 0.045),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: EdgeInsets.only(left: size.width * 0.04),
                child: Row(
                  children: [
                    Text(
                      "You'll be missed!",
                      style: AppTextStyles.h3.copyWith(
                        color: Colors.black,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () => Navigator.pop(ctx),
                      icon: Icon(
                        Icons.close,
                        color: Colors.black,
                        size: size.width * 0.06,
                      ),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: const Divider(color: Colors.black, thickness: 0.5),
              ),
              SizedBox(height: size.width * 0.02),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: size.width * 0.04),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(size.width * 0.04),
                        border: Border.all(color: Colors.black),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(size.width * 0.04),
                        child: Image.asset(
                          'assets/rabbits/logout_rabbit.png',
                          height: size.width * 0.30,
                          width: size.width * 0.35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Text(
                        'Are you sure you want to logout? We hope to see you back soon.',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: Colors.black,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: size.width * 0.04),
              Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: size.width * 0.04,
                  vertical: size.width * 0.04,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: size.width * 0.12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                            ),
                          ),
                          onPressed: () {
                            Navigator.pop(ctx);
                            _logout();
                          },
                          child: Text(
                            'Logout',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.038,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: SizedBox(
                        height: size.width * 0.12,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                size.width * 0.03,
                              ),
                            ),
                          ),
                          onPressed: () => Navigator.pop(ctx),
                          child: Text(
                            'Stay logged in',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: size.width * 0.038,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    // Server-driven visibility (defaults to all-visible before first load).
    final menu = context.watch<AppSettingsCubit>().current.menu;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: EmployeeAppBar(
        isOnline: _onDuty,
        onProfileTap: () => _open(AppRoutes.profile),
      ),
      body: ListView(
        padding: EdgeInsets.symmetric(
          horizontal: size.width * 0.04,
          vertical: size.width * 0.012,
        ),
        children: [
          // ── Duty toggle ──────────────────────────────────────────────────
          Padding(
            padding: EdgeInsets.symmetric(vertical: size.width * 0.013),
            child: Row(
              children: [
                ImageIcon(
                  const AssetImage('assets/markers/location1.webp'),
                  size: size.width * numD06,
                  color: Colors.black,
                ),
                SizedBox(width: size.width * 0.03),
                Expanded(
                  child: Row(
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            style: AppTextStyles.bodyMedium2,

                            children: [
                              const TextSpan(text: 'Toggle to go '),
                              TextSpan(
                                text: _onDuty ? 'Off Duty' : 'On Duty',
                                style: AppTextStyles.bodyMedium2.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4, right: 2),
                            child: Text(
                              _onDuty ? 'Online' : 'Offline',
                              style: AppTextStyles.labelSmall.copyWith(
                                fontWeight: FontWeight.w500,
                                color: Colors.grey.shade500,
                              ),
                            ),
                          ),
                          FlutterSwitch(
                            width: 55,
                            height: 27,
                            padding: 2,
                            value: _onDuty,
                            inactiveColor: Colors.grey.shade400,
                            activeColor: AppColors.primary,
                            onToggle: (v) {
                              if (v) {
                                // Going ON duty → verify uniform.
                                setState(() => _onDuty = true);
                                context.push(AppRoutes.uniformVerification);
                              } else {
                                // Going OFF duty → confirm first. The switch
                                // stays on until the user confirms in the popup.
                                _showGoOffDutyDialog();
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const Divider(thickness: 1.5, color: colorLightGrey),
          SizedBox(height: size.width * 0.01),

          // ── MY ACCOUNT ───────────────────────────────────────────────────
          _buildGroupSection(
            title: 'MY ACCOUNT',
            size: size,
            items: [
              _MenuGroupItem(
                name: 'My profile',
                iconPath: '${_iconsPath}ic_my_profile.svg',
                iconColor: const Color(0xFF4A80F0),
                iconBgColor: const Color(0xFFEEF2FF),
                onTap: () => _open(AppRoutes.profile),
              ),
              _MenuGroupItem(
                name: 'Digital ID',
                iconPath: '${_iconsPath}ic_digital_id.svg',
                iconColor: const Color(0xFF2DC78A),
                iconBgColor: const Color(0xFFE6F9F2),
                iconSize: size.width * 0.069,
                onTap: () => _open(AppRoutes.digitalId),
              ),
              _MenuGroupItem(
                name: 'Notifications',
                iconPath: '${_iconsPath}ic_feed.png',
                iconColor: AppColors.primary,
                iconBgColor: const Color(0xFFFFF8EC),
                badgeCount: _notificationCount,
                alwaysShowBadge: true,
                onTap: () => _open(AppRoutes.notifications),
              ),
            ],
          ),

          SizedBox(height: size.width * 0.012),

          // ── WORK HUB ─────────────────────────────────────────────────────
          _buildGroupSection(
            title: 'WORK HUB',
            size: size,
            items: [
              _MenuGroupItem(
                name: 'View tasks',
                iconPath: '${_iconsPath}ic_task1.png',
                iconColor: const Color(0xFF4A80F0),
                iconBgColor: const Color(0xFFEEF2FF),
                onTap: () => _open(AppRoutes.tasks),
              ),
              _MenuGroupItem(
                name: 'Evidence',
                iconPath: '${_iconsPath}ic_content1.png',
                iconColor: const Color(0xFF2DC78A),
                iconBgColor: const Color(0xFFE6F9F2),
                onTap: () => _open('${AppRoutes.evidence}?hideLeading=false'),
              ),
              if (menu.form)
                _MenuGroupItem(
                  name: 'Submit form',
                  iconPath: '${_iconsPath}ic_form_icon1.svg',
                  iconColor: const Color(0xFF7B61FF),
                  iconBgColor: const Color(0xFFF0EEFF),
                  iconSize: size.width * 0.078,
                  onTap: () => _open(AppRoutes.submitForms),
                ),
              if (menu.mileage)
                _MenuGroupItem(
                  name: 'Track mileage',
                  iconPath: '${_iconsPath}ic_mileage.png',
                  iconColor: const Color(0xFFF59E0B),
                  iconBgColor: const Color(0xFFFFF8EC),
                  iconSize: size.width * 0.068,
                  onTap: () => _open(AppRoutes.trackMileage),
                ),
              if (menu.claimExpenses)
                _MenuGroupItem(
                  name: 'Claim expenses',
                  iconPath: '${_iconsPath}ic_expenses.png',
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconSize: size.width * 0.070,
                  onTap: () => _open(AppRoutes.claimExpenses),
                ),
            ],
          ),

          SizedBox(height: size.width * 0.012),

          // ── PAY HUB ──────────────────────────────────────────────────────
          _buildGroupSection(
            title: 'PAY HUB',
            size: size,
            items: [
              _MenuGroupItem(
                name: 'Duties',
                iconPath: '${_iconsPath}ic_duties.svg',
                iconColor: const Color(0xFF3B82F6),
                iconBgColor: const Color(0xFFEFF6FF),
                iconSize: size.width * 0.058,
                onTap: () => _open(AppRoutes.duties),
              ),
              _MenuGroupItem(
                name: 'Attendance log',
                iconPath: '${_iconsPath}ic_attendance_log.svg',
                iconColor: const Color(0xFFE11D48),
                iconBgColor: const Color(0xFFFFE4E6),
                onTap: () => _open(AppRoutes.attendance),
              ),
              if (menu.payslip)
                _MenuGroupItem(
                  name: 'Payslip',
                  iconPath: '${_iconsPath}ic_piggy.png',
                  iconColor: const Color(0xFF10B981),
                  iconBgColor: const Color(0xFFD1FAE5),
                  iconSize: size.width * 0.076,
                  onTap: () => _open(AppRoutes.payslip),
                ),
              if (menu.viewEarnings)
                _MenuGroupItem(
                  name: 'View earnings',
                  iconPath: '${_iconsPath}ic_view_earnings.svg',
                  iconColor: const Color(0xFFF59E0B),
                  iconBgColor: const Color(0xFFFEF3C7),
                  onTap: () => _open(AppRoutes.earnings),
                ),
              _MenuGroupItem(
                name: 'My documents',
                iconPath: '${_iconsPath}ic_upload_documents.png',
                iconColor: const Color(0xFF6366F1),
                iconBgColor: const Color(0xFFE0E7FF),
                iconSize: size.width * 0.064,
                onTap: () => _open(AppRoutes.documents),
              ),
            ],
          ),

          SizedBox(height: size.width * 0.012),

          // ── SAFETY & SUPPORT ─────────────────────────────────────────────
          _buildGroupSection(
            title: 'SAFETY & SUPPORT',
            size: size,
            items: [
              _MenuGroupItem(
                name: 'Share alert',
                iconPath: '${_iconsPath}ic_alert2.png',
                iconColor: const Color(0xFFF59E0B),
                iconBgColor: const Color(0xFFFFF8EC),
                onTap: () => context
                    .findAncestorStateOfType<DashboardScreenState>()
                    ?.openTeamMap(shareAlert: true),
              ),
              _MenuGroupItem(
                name: 'SOS',
                iconPath: '${_iconsPath}ic_alert.png',
                iconColor: const Color(0xFFEF4444),
                iconBgColor: const Color(0xFFFFEEEE),
                iconSize: size.width * 0.074,
                onTap: () => context
                    .findAncestorStateOfType<DashboardScreenState>()
                    ?.openTeamMap(sos: true),
              ),
              _MenuGroupItem(
                name: 'Chat',
                iconPath: '${_iconsPath}ic_chat.png',
                iconColor: const Color(0xFF4A80F0),
                iconBgColor: const Color(0xFFEEF2FF),
                onTap: () => _open(AppRoutes.teamChatList),
              ),
            ],
          ),

          SizedBox(height: size.width * 0.012),

          // ── MORE ─────────────────────────────────────────────────────────
          _buildGroupSection(
            title: 'MORE',
            size: size,
            items: [
              if (menu.faq)
                _MenuGroupItem(
                  name: 'FAQs',
                  iconPath: '${_iconsPath}ic_faq.png',
                  iconColor: const Color(0xFF7B61FF),
                  iconBgColor: const Color(0xFFF0EEFF),
                  onTap: () => _open(
                    AppRoutes.faq,
                    extra: {
                      'priceTipsSelected': false,
                      'type': 'faq',
                      'index': 0,
                    },
                  ),
                ),
              if (menu.legalTerms)
                _MenuGroupItem(
                  name: 'Legal T&Cs',
                  iconPath: '${_iconsPath}ic_legal.svg',
                  iconColor: const Color(0xFF3B82F6),
                  iconBgColor: const Color(0xFFEFF6FF),
                  iconSize: size.width * 0.062,
                  onTap: () =>
                      _open(AppRoutes.termCheck, extra: {'type': 'legal'}),
                ),
              if (menu.privacyPolicy)
                _MenuGroupItem(
                  name: 'Privacy policy',
                  iconPath: '${_iconsPath}ic_privacy.svg',
                  iconColor: const Color(0xFF7B61FF),
                  iconBgColor: const Color(0xFFF0EEFF),
                  iconSize: size.width * 0.068,
                  onTap: () => _open(
                    AppRoutes.termCheck,
                    extra: {'type': 'privacy_policy'},
                  ),
                ),

              // _MenuGroupItem(
              //   name: 'Contact Us',
              //   iconPath: '${_iconsPath}ic_contact_us.png',
              //   iconColor: const Color(0xFF3B82F6),
              //   iconBgColor: const Color(0xFFEFF6FF),
              //   iconSize: size.width * 0.062,
              //   onTap: () => _open(const ContactUsScreen()),
              // ),
              // _MenuGroupItem(
              //   name: 'Change password',
              //   iconPath: '${_iconsPath}ic_key.png',
              //   iconColor: const Color(0xFFF59E0B),
              //   iconBgColor: const Color(0xFFFEF3C7),
              //   iconSize: size.width * 0.055,
              //   onTap: () => _open(const ChangePasswordScreen()),
              // ),
              _MenuGroupItem(
                name: 'Logout',
                iconPath: '${_iconsPath}ic_logout.png',
                iconColor: const Color(0xFFEF4444),
                iconBgColor: const Color(0xFFFFEEEE),
                iconSize: size.width * 0.068,
                onTap: _logoutDialog,
              ),
            ],
          ),

          SizedBox(height: size.width * 0.22),
        ],
      ),
    );
  }

  Widget _buildGroupSection({
    required String title,
    required Size size,
    required List<_MenuGroupItem> items,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.only(left: 4, bottom: size.width * 0.01),
          child: Text(
            title,
            style: AppTextStyles.caption.copyWith(
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade500,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(borderRadius: BorderRadius.circular(16)),
          child: Column(
            children: items.asMap().entries.map((entry) {
              final i = entry.key;
              final item = entry.value;
              final isLast = i == items.length - 1;
              return Column(
                children: [
                  InkWell(
                    onTap: item.onTap,
                    borderRadius: BorderRadius.vertical(
                      top: i == 0 ? const Radius.circular(16) : Radius.zero,
                      bottom: isLast ? const Radius.circular(16) : Radius.zero,
                    ),
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: size.width * 0.022,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: size.width * 0.085,
                            height: size.width * 0.085,
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                _buildIcon(item, size),
                                if (item.badgeCount > 0 || item.alwaysShowBadge)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      padding: const EdgeInsets.all(1.5),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: CircleAvatar(
                                        backgroundColor: item.badgeCount > 0
                                            ? item.iconColor
                                            : Colors.grey.shade400,
                                        radius: size.width * 0.018,
                                        child: Text(
                                          item.badgeCount.toString(),
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontSize: size.width * 0.02,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          SizedBox(width: size.width * 0.025),
                          Text(
                            item.name,
                            style: AppTextStyles.bodyMedium2.copyWith(
                              color: Colors.black,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const Spacer(),
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            color: Colors.black,
                            size: size.width * 0.04,
                          ),
                        ],
                      ),
                    ),
                  ),
                  if (!isLast)
                    const Divider(
                      height: 1,
                      thickness: 2,
                      color: colorLightGrey,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildIcon(_MenuGroupItem item, Size size) {
    if (item.name == 'Notifications') {
      return Container(
        margin: const EdgeInsets.only(top: 5),
        height: size.width * numD06,
        width: size.width * numD06,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.black, width: 1.2),
          borderRadius: BorderRadius.circular(size.width * numD015),
        ),
      );
    }
    final double iconSize = item.iconSize ?? (size.width * 0.06);
    if (item.iconPath.endsWith('.svg')) {
      return SvgPicture.asset(
        item.iconPath,
        width: iconSize,
        height: iconSize,
        colorFilter: const ColorFilter.mode(Colors.black, BlendMode.srcIn),
      );
    }
    return ImageIcon(
      AssetImage(item.iconPath),
      size: iconSize,
      color: Colors.black,
    );
  }
}

class _MenuGroupItem {
  final String name;
  final String iconPath;
  final Color iconColor;
  final Color iconBgColor;
  final int badgeCount;
  final bool alwaysShowBadge;
  final VoidCallback onTap;
  final double? iconSize;

  const _MenuGroupItem({
    required this.name,
    required this.iconPath,
    required this.iconColor,
    required this.iconBgColor,
    this.badgeCount = 0,
    this.alwaysShowBadge = false,
    required this.onTap,
    this.iconSize,
  });
}
