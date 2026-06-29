import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/config/routes/app_router.dart';
import 'package:presshop_enterprise/features/duties/data/models/duty_shift_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../profile/presentation/bloc/profile_bloc.dart';
import '../../../attendance/presentation/bloc/attendance_bloc.dart';
import '../../../../common/widgets/employee_app_bar.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_dimensions.dart';
import 'dashboard_screen.dart';

class HomeScreen3 extends StatefulWidget {
  const HomeScreen3({super.key});

  @override
  State<HomeScreen3> createState() => _HomeScreen3State();
}

class _HomeScreen3State extends State<HomeScreen3> {
  DateTime? _localCheckInTime;

  Stream<int>? _dutyTimerStream;

  String _formatDistance(double value) {
    final isInt = value == value.roundToDouble();
    final valStr = isInt ? value.toInt().toString() : value.toStringAsFixed(1);
    return '$valStr ${value == 1.0 ? 'mile' : 'miles'}';
  }

  String _formatItemsCount(int count) {
    return 'View $count ${count == 1 ? 'item' : 'items'}';
  }

  void _navigateToTab(int index) {
    context.findAncestorStateOfType<DashboardScreenState>()?.changeTab(index);
  }

  // String _getGreeting() {
  //   final hour = DateTime.now().hour;
  //   if (hour < 12) return 'GOOD MORNING';
  //   if (hour < 17) return 'GOOD AFTERNOON';
  //   return 'GOOD EVENING';
  // }

  String _formatDuration(int seconds) {
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    final s = seconds % 60;
    return '${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _activateDutyTimer(DateTime checkInTime) {
    _localCheckInTime = checkInTime;
    _dutyTimerStream = Stream.periodic(const Duration(seconds: 1), (i) => i);
  }

  void _deactivateDutyTimer() {
    _localCheckInTime = null;
    _dutyTimerStream = null;
  }

  Future<void> _saveCheckInTime(DateTime time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('check_in_timestamp', time.millisecondsSinceEpoch);
  }

  Future<void> _clearCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('check_in_timestamp');
  }

  Future<void> _loadCheckInTime() async {
    final prefs = await SharedPreferences.getInstance();
    final ts = prefs.getInt('check_in_timestamp');
    if (ts != null && mounted) {
      setState(() {
        _activateDutyTimer(DateTime.fromMillisecondsSinceEpoch(ts));
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _loadCheckInTime();
    context.read<AttendanceBloc>().add(const FetchAttendanceLog());
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocListener(
      listeners: [
        BlocListener<AttendanceBloc, AttendanceState>(
          listener: (context, state) {
            if (state is AttendanceActionSuccess) {
              if (state.isCheckedIn) {
                final now = DateTime.now();
                _saveCheckInTime(now);
                setState(() => _activateDutyTimer(now));
              } else {
                _clearCheckInTime();
                setState(() => _deactivateDutyTimer());
              }
              context.read<AttendanceBloc>().add(const FetchAttendanceLog());
            } else if (state is AttendanceLoaded) {
              if (state.isCheckedIn && _localCheckInTime == null) {
                final logTime = state.logs.isNotEmpty
                    ? state.logs.first.checkIn
                    : null;
                final checkInTime = logTime ?? DateTime.now();
                _saveCheckInTime(checkInTime);
                setState(() => _activateDutyTimer(checkInTime));
              } else if (!state.isCheckedIn && _localCheckInTime != null) {
                _clearCheckInTime();
                setState(() => _deactivateDutyTimer());
              }
            } else if (state is AttendanceError) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: AppColors.error,
                  content: Text(state.message),
                ),
              );
            }
          },
        ),
      ],
      child: BlocBuilder<ProfileBloc, ProfileState>(
        builder: (context, profileState) {
          final profile = profileState is ProfileLoaded
              ? profileState.profile
              : null;
          return BlocBuilder<AttendanceBloc, AttendanceState>(
            builder: (context, attendanceState) {
              final isCheckedIn = attendanceState is AttendanceLoaded
                  ? attendanceState.isCheckedIn
                  : false;
              final logs = attendanceState is AttendanceLoaded
                  ? attendanceState.logs
                  : [];
              final latestLog = logs.isNotEmpty ? logs.first : null;

              final checkInTimeStr = isCheckedIn
                  ? DateFormat('hh:mm a').format(
                      _localCheckInTime ?? latestLog?.checkIn ?? DateTime.now(),
                    )
                  : '09:03 AM';
              final siteStr = profile?.currentLocation?.isNotEmpty == true
                  ? profile!.currentLocation!
                  : 'MG Road, Bengaluru';
              final mileageStr = _formatDistance(isCheckedIn ? 18.0 : 0.0);

              return Scaffold(
                backgroundColor: const Color(0xFFF2F4F8),
                appBar: EmployeeAppBar(
                  onProfileTap: () => _navigateToTab(4),
                  isOnline: isCheckedIn,
                ),
                body: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.only(
                    left: 16.w,
                    right: 16.w,
                    top: 16.h,
                    bottom: 96.h,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDutyCard(
                        isCheckedIn,
                        checkInTimeStr,
                        siteStr,
                        mileageStr,
                      ),
                      SizedBox(height: 16.h),
                      _buildCameraShortcutCard(),
                      // SizedBox(height: 6.h),
                      _buildTasksCard(),
                      SizedBox(height: 16.h),
                      _buildDutiesCard(),
                      SizedBox(height: 16.h),
                      // _buildStatsGrid(),
                      // SizedBox(height: 16.h),
                      _buildRecentAttendanceCard(),
                      SizedBox(height: 16.h),
                      _buildRecentEarningsCard(),
                      SizedBox(height: 16.h),
                      _buildRecentMileageCard(),
                      SizedBox(height: 16.h),
                      _buildAttentionSection(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── Duty Card ─────────────────────────────────────────────────────────────

  Widget _buildDutyCard(
    bool isOnline,
    String checkInTime,
    String site,
    String mileage,
  ) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22.r),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E66FF), Color(0xFF1540C0)],
        ),
      ),
      child: Column(
        children: [
          // Row 1: status badge + shift + view details
          GestureDetector(
            onTap: () => context.push(AppRoutes.attendance),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6.w,
                      height: 6.w,
                      decoration: BoxDecoration(
                        color: isOnline
                            ? const Color(0xFF7DF3A8)
                            : Colors.grey.shade400,
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Text(
                      isOnline ? 'ON DUTY' : 'OFF DUTY',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'SHIFT 9:00–18:00',
                      style: AppTextStyles.labelSmall.copyWith(
                        color: Colors.white.withValues(alpha: 0.7),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(width: 6.w),
                    Icon(
                      Icons.chevron_right,
                      color: Colors.white.withValues(alpha: 0.7),
                      size: 14.sp,
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(height: 18.h),
          // Row 2: gauge + detail rows
          Row(
            children: [
              StreamBuilder<int>(
                stream: _dutyTimerStream,
                builder: (context, _) {
                  const shiftSeconds = 8 * 3600; // 8-hour shift
                  final elapsed = _localCheckInTime == null
                      ? 0
                      : DateTime.now()
                            .difference(_localCheckInTime!)
                            .inSeconds
                            .clamp(0, shiftSeconds);
                  final remaining = shiftSeconds - elapsed;
                  final progress = remaining / shiftSeconds;
                  return SizedBox(
                    width: 80.w,
                    height: 80.w,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 80.w,
                          height: 80.w,
                          child: CircularProgressIndicator(
                            value: isOnline ? progress : 1.0,
                            strokeWidth: 5.w,
                            backgroundColor: Colors.white.withValues(
                              alpha: 0.22,
                            ),
                            valueColor: const AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 68.w,
                          height: 68.w,
                          decoration: const BoxDecoration(
                            color: Color(0xFF1742C7),
                            shape: BoxShape.circle,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                isOnline
                                    ? _formatDuration(remaining)
                                    : '08:00:00',
                                maxLines: 1,
                                softWrap: false,
                                style: AppTextStyles.bodyMedium.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              Text(
                                isOnline ? 'ON DUTY' : 'OFF DUTY',
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize:
                                      7.0, // Constrained small font size for gauge label
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              SizedBox(width: 20.w),
              Expanded(
                child: Column(
                  children: [
                    _buildDutyDetailRow('Logged on', checkInTime),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.14),
                        height: 1,
                      ),
                    ),
                    _buildDutyDetailRow('Site', site),
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 4.h),
                      child: Divider(
                        color: Colors.white.withValues(alpha: 0.14),
                        height: 1,
                      ),
                    ),
                    _buildDutyDetailRow('Mileage today', mileage),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 18.h),
          GestureDetector(
            onTap: () {
              if (isOnline) {
                context.read<AttendanceBloc>().add(
                  const CheckOutRequested(0.0, 0.0),
                );
              } else {
                // Open uniform verification before allowing check-in.
                final bloc = context.read<AttendanceBloc>();
                context.push(AppRoutes.uniformVerification, extra: bloc);
              }
            },
            child: Container(
              width: double.infinity,
              height: 36.h,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13.r),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    isOnline ? Icons.logout : Icons.login,
                    color: const Color(0xFF1540C0),
                    size: 16.sp,
                  ),
                  SizedBox(width: 8.w),
                  Text(
                    isOnline ? 'Log Off Duty' : 'Log On Duty',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: const Color(0xFF1540C0),
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDutyDetailRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white.withValues(alpha: 0.7),
          ),
        ),
        Text(
          value,
          style: AppTextStyles.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }

  // ── Tasks Card ────────────────────────────────────────────────────────────

  Widget _buildTasksCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => _navigateToTab(1),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FE),
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: const Color(0xFFD5E2FD)),
                  ),
                  child: Icon(
                    LucideIcons.list_todo,
                    color: const Color(0xFF1F5BF6),
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tasks',
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    Text(
                      'This month · 8 assigned',
                      style: TextStyle(
                        color: const Color(0xFF5A6373),
                        fontSize: 10.5.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9AA2B1),
                  size: 16.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildTaskStatColumn('8', 'ACCEPTED', const Color(0xFF1F5BF6)),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildTaskStatColumn('5', 'COMPLETED', const Color(0xFF127A45)),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildTaskStatColumn('3', 'PENDING', const Color(0xFF9A6411)),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildTaskStatColumn('92%', 'ON TIME', const Color(0xFF0B0F1A)),
            ],
          ),
          SizedBox(height: 16.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(3.5.r),
            child: SizedBox(
              height: 7.h,
              width: double.infinity,
              child: LinearProgressIndicator(
                value: 5 / 8,
                backgroundColor: const Color(0xFFE5E8EE),
                valueColor: const AlwaysStoppedAnimation<Color>(
                  Color(0xFF1F5BF6),
                ),
              ),
            ),
          ),
          SizedBox(height: 14.h),

          const Divider(height: 1, color: Color(0xFFEFF1F5)),
          SizedBox(height: 12.h),
          Text(
            'HISTORY',
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 10.h),
          _buildRecentTaskRow(
            title: 'Site Visit – MG Road',
            time: 'Today · 10:00 AM',
            status: 'In Progress',
            statusColor: const Color(0xFF1F5BF6),
            statusBg: const Color(0xFFEAF1FE),
          ),
          SizedBox(height: 8.h),
          _buildRecentTaskRow(
            title: 'Photo Assignment – Andheri',
            time: 'Yesterday · 2:30 PM',
            status: 'Completed',
            statusColor: const Color(0xFF127A45),
            statusBg: const Color(0xFFEAF5EE),
          ),

          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EVIDENCE SUBMITTED',
                style: TextStyle(
                  color: const Color(0xFF9AA2B1),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              GestureDetector(
                onTap: () => _navigateToTab(0),
                behavior: HitTestBehavior.opaque,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      height: 24.w,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Align(
                            widthFactor: 0.6,
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1504711434969-e33886168f5c?w=50&h=50&fit=crop',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            widthFactor: 0.6,
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1527192491265-7e15c55b1ed2?w=50&h=50&fit=crop',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                          Align(
                            widthFactor: 0.6,
                            child: Container(
                              width: 24.w,
                              height: 24.w,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 1.5,
                                ),
                                image: const DecorationImage(
                                  image: NetworkImage(
                                    'https://images.unsplash.com/photo-1495020689067-958852a7765e?w=50&h=50&fit=crop',
                                  ),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Text(
                      _formatItemsCount(14),
                      style: TextStyle(
                        decoration: TextDecoration.underline,
                        color: const Color(0xFF0B0F1A),
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTaskStatColumn(String val, String label, Color color) {
    return Column(
      children: [
        Text(
          val,
          style: AppTextStyles.h4.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: AppTextStyles.overline.copyWith(
            color: const Color(0xFF5A6373),
            fontWeight: FontWeight.w700,
            letterSpacing: 0.3,
            fontSize: 8.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Needs your attention',
              style: TextStyle(
                color: const Color(0xFF0B0F1A),
                fontSize: 13.5.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'AirbnbCereal',
              ),
            ),
          ],
        ),
        SizedBox(height: 10.h),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18.r),
            border: Border.all(color: const Color(0xFFEFF1F5)),
          ),
          child: Column(
            children: [
              _buildAttentionItem(
                icon: LucideIcons.calendar,
                iconColor: const Color(0xFF9A6411),
                iconBgColor: const Color(0xFFFAF1E2),
                iconBorderColor: const Color(0xFFF0E2C6),
                title: 'Leave approval pending',
                subtitle: 'Casual · Jun 18–19 · awaiting Priya K.',
                badgeText: '1',
                badgeColor: const Color(0xFF9A6411),
                onTap: () => _navigateToTab(4),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: const Divider(color: Color(0xFFEFF1F5), height: 1),
              ),
              _buildAttentionItem(
                icon: LucideIcons.receipt,
                iconColor: const Color(0xFF9A6411),
                iconBgColor: const Color(0xFFFAF1E2),
                iconBorderColor: const Color(0xFFF0E2C6),
                title: 'Pending claims',
                subtitle: 'Travel ₹2,400 · fuel ₹1,150',
                badgeText: '2',
                badgeColor: const Color(0xFF9A6411),
                onTap: () => context.push(AppRoutes.claimExpenses),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: const Divider(color: Color(0xFFEFF1F5), height: 1),
              ),
              _buildAttentionItem(
                icon: LucideIcons.bell,
                iconColor: const Color(0xFF1F5BF6),
                iconBgColor: const Color(0xFFEAF1FE),
                iconBorderColor: const Color(0xFFD5E2FD),
                title: 'Missed notifications',
                subtitle: 'New task broadcast · roster update',
                badgeText: '3',
                badgeColor: const Color(0xFF1F5BF6),
                onTap: () => context.push(AppRoutes.notifications),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: const Divider(color: Color(0xFFEFF1F5), height: 1),
              ),
              _buildAttentionItem(
                icon: LucideIcons.message_square,
                iconColor: const Color(0xFF1F5BF6),
                iconBgColor: const Color(0xFFEAF1FE),
                iconBorderColor: const Color(0xFFD5E2FD),
                title: 'Unread chats',
                subtitle: 'Priya K. · Daily Globe desk',
                badgeText: '2',
                badgeColor: const Color(0xFF1F5BF6),
                onTap: () => _navigateToTab(3),
              ),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 14.w),
                child: const Divider(color: Color(0xFFEFF1F5), height: 1),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.notifications),
                borderRadius: BorderRadius.only(
                  bottomLeft: Radius.circular(18.r),
                  bottomRight: Radius.circular(18.r),
                ),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 13.h),
                  child: Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Show more',
                          style: TextStyle(
                            color: const Color(0xFF1F5BF6),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                        SizedBox(width: 4.w),
                        Icon(
                          Icons.chevron_right,
                          color: const Color(0xFF1F5BF6),
                          size: 16.sp,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAttentionItem({
    required IconData icon,
    required Color iconColor,
    required Color iconBgColor,
    required Color iconBorderColor,
    required String title,
    required String subtitle,
    required String badgeText,
    required Color badgeColor,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12.r),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 12.h),
        child: Row(
          children: [
            Container(
              width: 38.w,
              height: 38.w,
              decoration: BoxDecoration(
                color: iconBgColor,
                borderRadius: BorderRadius.circular(11.r),
                border: Border.all(color: iconBorderColor),
              ),
              child: Icon(icon, color: iconColor, size: 18.sp),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      color: const Color(0xFF0B0F1A),
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: const Color(0xFF5A6373),
                      fontSize: 10.5.sp,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              width: 22.w,
              height: 20.h,
              decoration: BoxDecoration(
                color: badgeColor,
                borderRadius: BorderRadius.circular(10.r),
              ),
              child: Center(
                child: Text(
                  badgeText,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10.sp,
                    fontWeight: FontWeight.w800,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Camera Shortcut ───────────────────────────────────────────────────────

  Widget _buildCameraShortcutCard() {
    return Container(
      margin: EdgeInsets.only(bottom: 16.h),
      decoration: BoxDecoration(
        color: const Color(0xFF0A0F1D),
        borderRadius: BorderRadius.circular(16.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 16.h),
        child: Row(
          children: [
            Container(
              width: 44.w,
              height: 44.w,
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Center(
                child: Icon(
                  LucideIcons.camera,
                  color: Colors.white,
                  size: 20.sp,
                ),
              ),
            ),
            SizedBox(width: 12.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Capture the moment',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 13.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    'Shoot & submit field evidence',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 10.sp,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(width: 8.w),
            GestureDetector(
              onTap: () => context.push(AppRoutes.employeeCamera),
              child: Container(
                padding: EdgeInsets.symmetric(horizontal: 11.w, vertical: 9.h),
                decoration: BoxDecoration(
                  color: const Color(0xFF1F5BF6),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.camera, color: Colors.white, size: 12.sp),
                    SizedBox(width: 5.w),
                    Text(
                      'Open camera',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 11.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Recent Helpers ────────────────────────────────────────────────────────

  Widget _buildDutiesCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.duties),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FE),
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: const Color(0xFFD5E2FD)),
                  ),
                  child: Icon(
                    LucideIcons.briefcase,
                    color: const Color(0xFF1F5BF6),
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Duties',
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    Text(
                      'This month · 22 shifts',
                      style: TextStyle(
                        color: const Color(0xFF5A6373),
                        fontSize: 10.5.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9AA2B1),
                  size: 16.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildDutyStat('9h 28m', 'Avg Shift'),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildDutyStat('208h', 'Total Hrs'),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildDutyStat('22', 'Shifts Done'),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFEFF1F5)),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HISTORY',
                style: TextStyle(
                  color: const Color(0xFF9AA2B1),
                  fontSize: 9.sp,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              GestureDetector(
                onTap: () => context.push(AppRoutes.dutiesHistory),
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.h),
                  child: Text(
                    'View All',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 10.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 10.h),
          Builder(
            builder: (context) {
              final mockShifts = DutyShiftHistory.getMockShifts();
              return Column(
                children: [
                  _buildDutyLogRow(mockShifts[0], isToday: true),
                  SizedBox(height: 8.h),
                  _buildDutyLogRow(mockShifts[1]),
                  SizedBox(height: 8.h),
                  _buildDutyLogRow(mockShifts[2]),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDutyStat(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: const Color(0xFF0B0F1A),
            fontSize: 14.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5A6373),
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'AirbnbCereal',
          ),
        ),
      ],
    );
  }

  Widget _buildDutyLogRow(DutyShiftHistory shift, {bool isToday = false}) {
    final formattedDate = DateFormat('EEE, MMM d').format(shift.date);
    return GestureDetector(
      onTap: () => context.push(AppRoutes.dutiesHistoryDetails, extra: shift),
      child: Container(
        color: Colors.transparent,
        child: Row(
          children: [
            Container(
              width: 28.w,
              height: 28.w,
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFEAF5EE)
                    : const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(8.r),
              ),
              child: Icon(
                LucideIcons.clock,
                color: isToday
                    ? const Color(0xFF127A45)
                    : const Color(0xFF9AA2B1),
                size: 13.sp,
              ),
            ),
            SizedBox(width: 10.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    formattedDate,
                    style: TextStyle(
                      color: const Color(0xFF0B0F1A),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w700,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    '${shift.checkInTime} – ${shift.checkOutTime}',
                    style: TextStyle(
                      color: const Color(0xFF9AA2B1),
                      fontSize: 10.sp,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
              decoration: BoxDecoration(
                color: isToday
                    ? const Color(0xFFEAF5EE)
                    : const Color(0xFFF3F5F9),
                borderRadius: BorderRadius.circular(6.r),
              ),
              child: Text(
                shift.duration,
                style: TextStyle(
                  color: isToday
                      ? const Color(0xFF127A45)
                      : const Color(0xFF5A6373),
                  fontSize: 10.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTaskRow({
    required String title,
    required String time,
    required String status,
    required Color statusColor,
    required Color statusBg,
  }) {
    return Row(
      children: [
        Container(
          width: 6.w,
          height: 6.w,
          decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
        ),
        SizedBox(width: 10.w),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  color: const Color(0xFF0B0F1A),
                  fontSize: 11.5.sp,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'AirbnbCereal',
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              SizedBox(height: 2.h),
              Text(
                time,
                style: TextStyle(
                  color: const Color(0xFF9AA2B1),
                  fontSize: 10.sp,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ],
          ),
        ),
        SizedBox(width: 8.w),
        Container(
          padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 3.h),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(6.r),
          ),
          child: Text(
            status,
            style: TextStyle(
              color: statusColor,
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildRecentAttendanceCard() {
    const days = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    const statuses = ['P', 'P', 'L', 'P', 'P', 'P', 'H'];

    Color bgFor(String s) => switch (s) {
      'P' => const Color(0xFFEAF5EE),
      'L' => const Color(0xFFFAF1E2),
      'A' => const Color(0xFFFEEFEF),
      _ => const Color(0xFFEFF1F5),
    };

    Color fgFor(String s) => switch (s) {
      'P' => const Color(0xFF127A45),
      'L' => const Color(0xFF9A6411),
      'A' => const Color(0xFFC23B36),
      _ => const Color(0xFF9AA2B1),
    };

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push(AppRoutes.attendance),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF5EE),
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: const Color(0xFFCDE9D8)),
                  ),
                  child: Icon(
                    LucideIcons.calendar_check,
                    color: const Color(0xFF127A45),
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Attendance',
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    Text(
                      'This week overview',
                      style: TextStyle(
                        color: const Color(0xFF5A6373),
                        fontSize: 10.5.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9AA2B1),
                  size: 16.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: List.generate(7, (i) {
              final s = statuses[i];
              return Column(
                children: [
                  Text(
                    days[i],
                    style: TextStyle(
                      color: const Color(0xFF9AA2B1),
                      fontSize: 9.sp,
                      fontFamily: 'AirbnbCereal',
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 5.h),
                  Container(
                    width: 30.w,
                    height: 30.w,
                    decoration: BoxDecoration(
                      color: bgFor(s),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        s,
                        style: TextStyle(
                          color: fgFor(s),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                  ),
                ],
              );
            }),
          ),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFEFF1F5)),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildAttendanceStat('22', 'Present', const Color(0xFF127A45)),
              Container(width: 1, height: 20.h, color: const Color(0xFFE5E8EE)),
              _buildAttendanceStat('1', 'Late', const Color(0xFF9A6411)),
              Container(width: 1, height: 20.h, color: const Color(0xFFE5E8EE)),
              _buildAttendanceStat('0', 'Absent', const Color(0xFFC23B36)),
              Container(width: 1, height: 20.h, color: const Color(0xFFE5E8EE)),
              _buildAttendanceStat('2', 'Holiday', const Color(0xFF5A6373)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAttendanceStat(String value, String label, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        SizedBox(height: 2.h),
        Text(
          label,
          style: TextStyle(
            color: const Color(0xFF5A6373),
            fontSize: 9.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'AirbnbCereal',
          ),
        ),
      ],
    );
  }

  Widget _buildRecentEarningsCard() {
    final entries = [
      ('Jun 15', 'Content Payout', '+₹2,400'),
      ('Jun 12', 'Expense Reimb.', '+₹1,150'),
      ('Jun 10', 'Task Bonus', '+₹800'),
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          GestureDetector(
            onTap: () => context.push(
              AppRoutes.earnings,
              extra: {'title': 'Earnings Detail', 'icon': LucideIcons.wallet},
            ),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Color(0xFF2E66FF), Color(0xFF1540C0)],
                    ),
                    borderRadius: BorderRadius.circular(11.r),
                  ),
                  child: Icon(
                    LucideIcons.wallet,
                    color: Colors.white,
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'View Earnings ',
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    Text(
                      'Last 3 transctions · June',
                      style: TextStyle(
                        color: const Color(0xFF5A6373),
                        fontSize: 10.5.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9AA2B1),
                  size: 16.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          ...List.generate(entries.length, (i) {
            final e = entries[i];
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  child: Row(
                    children: [
                      Container(
                        width: 8.w,
                        height: 8.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FE),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF1F5BF6),
                            width: 1.5,
                          ),
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Text(
                        e.$1,
                        style: TextStyle(
                          color: const Color(0xFF9AA2B1),
                          fontSize: 10.sp,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Text(
                          e.$2,
                          style: TextStyle(
                            color: const Color(0xFF0B0F1A),
                            fontSize: 11.5.sp,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                      Text(
                        e.$3,
                        style: TextStyle(
                          color: const Color(0xFF127A45),
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ],
                  ),
                ),
                if (i < entries.length - 1)
                  const Divider(height: 1, color: Color(0xFFEFF1F5)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildRecentMileageCard() {
    final trips = [
      ('Jun 16', 'Office → MG Road', '18 mi', '₹180'),
      ('Jun 15', 'MG Road → Andheri', '22 mi', '₹220'),
      ('Jun 14', 'Office → Bandra', '14 mi', '₹140'),
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          GestureDetector(
            onTap: () => context.push(AppRoutes.trackMileage),
            child: Row(
              children: [
                Container(
                  width: 34.w,
                  height: 34.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF1FE),
                    borderRadius: BorderRadius.circular(11.r),
                    border: Border.all(color: const Color(0xFFD5E2FD)),
                  ),
                  child: Icon(
                    LucideIcons.car,
                    color: const Color(0xFF1F5BF6),
                    size: 16.sp,
                  ),
                ),
                SizedBox(width: 10.w),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Mileage & Trips',
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.5.sp,
                        fontWeight: FontWeight.w800,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    Text(
                      '${_formatDistance(248.0)} total · June',
                      style: TextStyle(
                        color: const Color(0xFF5A6373),
                        fontSize: 10.5.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Icon(
                  Icons.chevron_right,
                  color: const Color(0xFF9AA2B1),
                  size: 16.sp,
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),

          // ── Vehicle section ──────────────────────────────────────────
          Text(
            'MY VEHICLE',
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 10.h),
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F8FF),
              borderRadius: BorderRadius.circular(14.r),
              border: Border.all(color: const Color(0xFFE0E9FD)),
            ),
            clipBehavior: Clip.antiAlias,
            child: Row(
              children: [
                // Vehicle image
                SizedBox(
                  width: 120.w,
                  height: 96.h,
                  child: Image.network(
                    'https://images.unsplash.com/photo-1552519507-da3b142c6e3d?w=300&h=200&fit=crop',
                    fit: BoxFit.cover,
                    errorBuilder: (ctx, err, st) => Container(
                      color: const Color(0xFFEAF1FE),
                      child: Icon(
                        LucideIcons.car,
                        color: const Color(0xFF1F5BF6),
                        size: 38.sp,
                      ),
                    ),
                  ),
                ),
                // Vehicle details
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 12.w,
                      vertical: 10.h,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Honda City',
                                style: TextStyle(
                                  color: const Color(0xFF0B0F1A),
                                  fontSize: 13.sp,
                                  fontWeight: FontWeight.w800,
                                  fontFamily: 'AirbnbCereal',
                                ),
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 6.w,
                                vertical: 2.h,
                              ),
                              decoration: BoxDecoration(
                                color: const Color(0xFFEAF5EE),
                                borderRadius: BorderRadius.circular(5.r),
                              ),
                              child: Text(
                                'Assigned',
                                style: TextStyle(
                                  color: const Color(0xFF127A45),
                                  fontSize: 8.5.sp,
                                  fontWeight: FontWeight.w700,
                                  fontFamily: 'AirbnbCereal',
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 5.h),
                        Row(
                          children: [
                            Icon(
                              LucideIcons.hash,
                              color: const Color(0xFF9AA2B1),
                              size: 10.sp,
                            ),
                            SizedBox(width: 3.w),
                            Text(
                              'MH 02 AB 1234',
                              style: TextStyle(
                                color: const Color(0xFF5A6373),
                                fontSize: 10.5.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'AirbnbCereal',
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 7.h),
                        Row(
                          children: [
                            _buildVehicleChip('Sedan'),
                            SizedBox(width: 5.w),
                            _buildVehicleChip('Petrol'),
                            SizedBox(width: 5.w),
                            _buildVehicleChip('White'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFEFF1F5)),
          SizedBox(height: 10.h),

          // ── Recent trips ─────────────────────────────────────────────
          Text(
            'RECENT TRIPS',
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 10.h),
          ...List.generate(trips.length, (i) {
            final t = trips[i];
            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(vertical: 9.h),
                  child: Row(
                    children: [
                      Container(
                        width: 28.w,
                        height: 28.w,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAF1FE),
                          borderRadius: BorderRadius.circular(8.r),
                        ),
                        child: Icon(
                          LucideIcons.map_pin,
                          color: const Color(0xFF1F5BF6),
                          size: 13.sp,
                        ),
                      ),
                      SizedBox(width: 10.w),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.$2,
                              style: TextStyle(
                                color: const Color(0xFF0B0F1A),
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                            SizedBox(height: 2.h),
                            Text(
                              t.$1,
                              style: TextStyle(
                                color: const Color(0xFF9AA2B1),
                                fontSize: 10.sp,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            t.$3,
                            style: TextStyle(
                              color: const Color(0xFF0B0F1A),
                              fontSize: 11.5.sp,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            t.$4,
                            style: TextStyle(
                              color: const Color(0xFF1F5BF6),
                              fontSize: 10.sp,
                              fontWeight: FontWeight.w600,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (i < trips.length - 1)
                  const Divider(height: 1, color: Color(0xFFEFF1F5)),
              ],
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVehicleChip(String label) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6.w, vertical: 2.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(5.r),
        border: Border.all(color: const Color(0xFFD5E2FD)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: const Color(0xFF1F5BF6),
          fontSize: 8.5.sp,
          fontWeight: FontWeight.w600,
          fontFamily: 'AirbnbCereal',
        ),
      ),
    );
  }
}
