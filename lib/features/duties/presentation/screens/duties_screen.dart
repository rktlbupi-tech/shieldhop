import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:presshop_enterprise/config/routes/app_router.dart';
import 'package:presshop_enterprise/features/map/core/map_constants.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../domain/entities/duty_entities.dart';
import '../bloc/duties_bloc.dart';

class DutiesScreen extends StatelessWidget {
  const DutiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DutiesBloc>()..add(const FetchDutiesOverview()),
      child: const _DutiesView(),
    );
  }
}

class _DutiesView extends StatefulWidget {
  const _DutiesView();

  @override
  State<_DutiesView> createState() => _DutiesViewState();
}

class _DutiesViewState extends State<_DutiesView> {
  final bool _isOnDuty = true;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Drives the live "remaining duty time" countdown (computed client-side).
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Remaining time until the shift end, computed from `shift.end_minute`.
  String _getRemainingTime(DutyShiftEntity? shift) {
    if (shift == null) return "--";
    final now = DateTime.now();
    final midnight = DateTime(now.year, now.month, now.day);
    final shiftEnd = midnight.add(Duration(minutes: shift.endMinute));
    if (!now.isBefore(shiftEnd)) return "00h 00m 00s";

    final diff = shiftEnd.difference(now);
    final h = diff.inHours.toString().padLeft(2, '0');
    final m = (diff.inMinutes % 60).toString().padLeft(2, '0');
    final s = (diff.inSeconds % 60).toString().padLeft(2, '0');
    return "${h}h ${m}m ${s}s";
  }

  void _showToast(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(fontFamily: 'AirbnbCereal'),
        ),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _callSupervisor(String? phone) async {
    if (phone == null || phone.trim().isEmpty) {
      _showToast("No supervisor phone number available");
      return;
    }
    final uri = Uri(scheme: 'tel', path: phone.trim());
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      _showToast("Could not open the dialer");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: AppAppBar(
        title: _isOnDuty ? "Duties" : "Log on",
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: BlocConsumer<DutiesBloc, DutiesState>(
        listenWhen: (prev, curr) =>
            curr is HandoverSubmitSuccess || curr is HandoverSubmitFailure,
        listener: (context, state) {
          if (state is HandoverSubmitSuccess) {
            _showToast("Handover report submitted to your supervisor.");
          } else if (state is HandoverSubmitFailure) {
            _showToast(state.errorMessage);
          }
        },
        builder: (context, state) {
          if (state is DutiesLoading || state is DutiesInitial) {
            return const Center(child: LoadingWidget());
          }
          if (state is DutiesError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () =>
                  context.read<DutiesBloc>().add(const FetchDutiesOverview()),
            );
          }

          final loaded =
              state is DutiesOverviewLoaded ? state : null;
          if (loaded == null) {
            return const Center(child: LoadingWidget());
          }

          final current = loaded.current;

          return SafeArea(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              children: [
                _buildStatusGradientCard(current),
                const SizedBox(height: 20),
                _buildTasksSection(loaded.todayTasks),
                const SizedBox(height: 20),
                _buildUpcomingDutiesSection(loaded.upcoming),
                const SizedBox(height: 20),
                _buildCurrentAssignmentCard(current),
                const SizedBox(height: 20),
                _buildThisMonthSection(current?.thisMonth),
                const SizedBox(height: 20),
                _buildHistoryCard(),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusGradientCard(DutyCurrentEntity? current) {
    final shift = current?.shift;
    final site = current?.site;
    final shiftLabel = shift != null ? "${shift.start} – ${shift.end}" : "No active shift";
    final dutyDays =
        (shift?.dutyDays.isNotEmpty ?? false) ? shift!.dutyDays.join(", ") : "—";
    final offDays =
        (shift?.offDays.isNotEmpty ?? false) ? shift!.offDays.join(", ") : "—";

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2979FF), Color(0xFF0D47A1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  shiftLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: "Duty days : ",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                    children: [
                      TextSpan(
                        text: dutyDays,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: "Off days     : ",
                    style: const TextStyle(
                      color: Colors.yellowAccent,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                    children: [
                      TextSpan(
                        text: offDays,
                        style: const TextStyle(
                          color: Colors.yellow,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 1,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
                const SizedBox(height: 8),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 2.0),
                      child: Icon(
                        LucideIcons.map_pin,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site?.name ?? "No site assigned",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          const SizedBox(height: 1),
                          Text(
                            site?.address ?? "",
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
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
          ),
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerRight,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.access_time, color: Colors.white),
                      const SizedBox(width: 4),
                      Text(
                        "Remaining \nduty time",
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _getRemainingTime(shift),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 19,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
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

  Widget _buildTasksSection(List<TodayTaskEntity> tasks) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Today’s Tasks",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: tasks.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: Text(
                    "No tasks for today",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: tasks.length,
                  itemBuilder: (context, index) {
                    final task = tasks[index];
                    final isLast = index == tasks.length - 1;
                    final isCompleted = task.isCompleted;

                    return IntrinsicHeight(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Column(
                            children: [
                              isCompleted
                                  ? const Icon(
                                      Icons.check_circle,
                                      color: colorEmployeeGreen1,
                                      size: 22,
                                    )
                                  : Container(
                                      width: 22,
                                      height: 22,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: Colors.grey.shade400,
                                          width: 1.5,
                                        ),
                                        color: Colors.white,
                                      ),
                                    ),
                              if (!isLast)
                                Expanded(
                                  child: Padding(
                                    padding:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    child: Column(
                                      children: List.generate(4, (i) {
                                        return Expanded(
                                          child: Container(
                                            width: 1.5,
                                            margin: const EdgeInsets.symmetric(
                                              vertical: 2.5,
                                            ),
                                            color: isCompleted
                                                ? colorEmployeeGreen1
                                                : Colors.grey.shade300,
                                          ),
                                        );
                                      }),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.only(
                                  top: 2.0, bottom: 20.0),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        color: Colors.black87,
                                        fontWeight: isCompleted
                                            ? FontWeight.w500
                                            : FontWeight.normal,
                                        fontFamily: 'AirbnbCereal',
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    isCompleted ? "Completed" : "Pending",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isCompleted
                                          ? colorEmployeeGreen1
                                          : Colors.grey.shade500,
                                      fontWeight: isCompleted
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      fontFamily: 'AirbnbCereal',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildCurrentAssignmentCard(DutyCurrentEntity? current) {
    final site = current?.site;
    final supervisor = current?.supervisor;
    final shift = current?.shift;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Current Duty Site",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        const SizedBox(height: 12),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE8F0FE),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        LucideIcons.building,
                        color: Color(0xFF1877F2),
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            site?.name ?? "No site assigned",
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            site?.address ?? "",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12.5,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          const SizedBox(height: 6),
                          RichText(
                            text: TextSpan(
                              text: "Supervisor: ",
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                                fontFamily: 'AirbnbCereal',
                              ),
                              children: [
                                TextSpan(
                                  text: supervisor?.name ?? "—",
                                  style: const TextStyle(
                                    color: Color(0xFF1877F2),
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (shift != null) ...[
                            const SizedBox(height: 3),
                            Text(
                              "Shift: ${shift.start} – ${shift.end}",
                              style: TextStyle(
                                color: Colors.grey.shade600,
                                fontSize: 12,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    GestureDetector(
                      onTap: () => _showToast("Map thumbnail clicked"),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          children: const [
                            Icon(
                              LucideIcons.map_pin,
                              color: Color(0xFF1877F2),
                              size: 20,
                            ),
                            SizedBox(height: 4),
                            Text(
                              "On Map",
                              style: TextStyle(
                                color: Color(0xFF1877F2),
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
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
              const SizedBox(height: 16),
              Divider(height: 1, color: Colors.grey.shade200),
              Row(
                children: [
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _showToast("View Map clicked"),
                      icon: const Icon(
                        LucideIcons.map,
                        size: 16,
                        color: Color(0xFF1877F2),
                      ),
                      label: const Text(
                        "View Map",
                        style: TextStyle(
                          color: Color(0xFF1877F2),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  Container(width: 1, height: 30, color: Colors.grey.shade200),
                  Expanded(
                    child: TextButton.icon(
                      onPressed: () => _callSupervisor(supervisor?.phone),
                      icon: const Icon(
                        LucideIcons.phone,
                        size: 16,
                        color: Color(0xFF2DC78A),
                      ),
                      label: const Text(
                        "Call Supervisor",
                        style: TextStyle(
                          color: Color(0xFF2DC78A),
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),
              Divider(height: 1, color: Colors.grey.shade200),
              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: () => _showHandoverReportDialog(
                    context,
                    site == null
                        ? ""
                        : [site.name, site.address]
                            .where((s) => s.isNotEmpty)
                            .join(", "),
                  ),
                  icon: const Icon(
                    LucideIcons.triangle_alert,
                    size: 16,
                    color: Color(0xFFFF3B30),
                  ),
                  label: const Text(
                    "Report Handover Issue (Next Shift)",
                    style: TextStyle(
                      color: Color(0xFFFF3B30),
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildUpcomingDutiesSection(List<UpcomingShiftEntity> upcoming) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Upcoming Tasks",
          style: TextStyle(
            color: Colors.black,
            fontSize: 16,
            fontWeight: FontWeight.bold,
            fontFamily: 'AirbnbCereal',
          ),
        ),
        const SizedBox(height: 12),
        if (upcoming.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade100),
            ),
            child: Text(
              "No upcoming shifts",
              style: TextStyle(
                color: Colors.grey.shade500,
                fontSize: 13,
                fontFamily: 'AirbnbCereal',
              ),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: upcoming.length,
            itemBuilder: (context, index) {
              final duty = upcoming[index];
              final day =
                  duty.date != null ? duty.date!.day.toString() : "--";
              final month = duty.date != null
                  ? DateFormat('MMM').format(duty.date!)
                  : "";
              final timeRange = "${duty.start} – ${duty.end}";

              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade100),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            day,
                            style: const TextStyle(
                              color: Color(0xFF1877F2),
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          Text(
                            month,
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 11,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            duty.name,
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 14.5,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                LucideIcons.map_pin,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  duty.site,
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 12,
                                    fontFamily: 'AirbnbCereal',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          timeRange,
                          style: const TextStyle(
                            color: Color(0xFF1877F2),
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEEF2FF),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            "Upcoming",
                            style: TextStyle(
                              color: Color(0xFF1877F2),
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  Widget _buildThisMonthSection(DutyMonthSummaryEntity? month) {
    final daysCompleted = month?.daysCompleted.toString() ?? "--";
    final totalHours = month != null
        ? (month.totalHours % 1 == 0
            ? month.totalHours.toStringAsFixed(0)
            : month.totalHours.toStringAsFixed(1))
        : "--";
    final attendance =
        month != null ? "${month.attendanceRate.toStringAsFixed(0)}%" : "--";

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "This Month's Summary",
            style: TextStyle(
              color: Colors.black,
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildMonthStat(
                  icon: LucideIcons.calendar_check,
                  iconBg: const Color(0xFFE8F8F0),
                  iconColor: const Color(0xFF2DC78A),
                  value: daysCompleted,
                  valueColor: const Color(0xFF2DC78A),
                  label: "Days Completed",
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMonthStat(
                  icon: LucideIcons.clock,
                  iconBg: const Color(0xFFEEF2FF),
                  iconColor: const Color(0xFF1877F2),
                  value: totalHours,
                  valueColor: const Color(0xFF1877F2),
                  label: "Total Hours",
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMonthStat(
                  icon: Icons.trending_up,
                  iconBg: const Color(0xFFF3E8FF),
                  iconColor: const Color(0xFF9333EA),
                  value: attendance,
                  valueColor: const Color(0xFF9333EA),
                  label: "Attendance",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMonthStat({
    required IconData icon,
    required Color iconBg,
    required Color iconColor,
    required String value,
    required Color valueColor,
    required String label,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  color: valueColor,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              Text(
                label,
                style: const TextStyle(
                  color: Colors.grey,
                  fontSize: 10,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showHandoverReportDialog(BuildContext context, String siteName) {
    final bloc = context.read<DutiesBloc>();
    final locationController = TextEditingController(text: siteName);
    final detailsController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        return AlertDialog(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: const [
              Icon(LucideIcons.triangle_alert, color: Color(0xFFFF3B30)),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  "Report Handover Issue",
                  style: TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  ),
                ),
              ),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Notify your supervisor if the next shift guard has not arrived or if there is a handover delay.",
                    style: TextStyle(
                      color: Colors.black54,
                      fontSize: 13,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Location / Site Name",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: locationController,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'AirbnbCereal',
                    ),
                    decoration: InputDecoration(
                      hintText: "Enter location name",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontFamily: 'AirbnbCereal',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Report Details / Comments",
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: Colors.black87,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  const SizedBox(height: 6),
                  TextFormField(
                    controller: detailsController,
                    maxLines: 4,
                    style: const TextStyle(
                      fontSize: 14,
                      fontFamily: 'AirbnbCereal',
                    ),
                    decoration: InputDecoration(
                      hintText:
                          "Describe the issue (e.g. Relief guard has not arrived yet, shift ended but relief not here, etc.)",
                      hintStyle: TextStyle(
                        color: Colors.grey.shade400,
                        fontSize: 12.5,
                        fontFamily: 'AirbnbCereal',
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                    ),
                    validator: (v) {
                      if (v == null || v.trim().isEmpty) {
                        return "Please enter report details";
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text(
                "Cancel",
                style: TextStyle(
                  color: Colors.grey,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                if (formKey.currentState?.validate() ?? false) {
                  bloc.add(SubmitHandoverReport(
                    siteName: locationController.text.trim(),
                    details: detailsController.text.trim(),
                  ));
                  Navigator.pop(dialogContext);
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFF3B30),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 10,
                ),
              ),
              child: const Text(
                "Submit Report",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildHistoryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade100),
      ),
      child: InkWell(
        onTap: () => context.push(AppRoutes.dutiesHistory),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Color(0xFFEAF1FE),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.history,
                color: Color(0xFF1877F2),
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    "View Shift History",
                    style: TextStyle(
                      color: Colors.black,
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    "Inspect all past duties and shift details",
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 11,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey, size: 20),
          ],
        ),
      ),
    );
  }
}
