import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../domain/entities/attendance_entity.dart';
import '../bloc/attendance_bloc.dart';
import '../../../../common/widgets/sliding_tabs.dart';
import '../../../../common/widgets/custom_dropdown.dart';

class AttendanceScreen extends StatelessWidget {
  const AttendanceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AttendanceBloc>()..add(const FetchAttendanceLog()),
      child: const _AttendanceView(),
    );
  }
}

class _AttendanceView extends StatefulWidget {
  const _AttendanceView();
  @override
  State<_AttendanceView> createState() => _AttendanceViewState();
}

class _AttendanceViewState extends State<_AttendanceView>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _queryFormKey = GlobalKey<FormState>();
  final _queryDetailsController = TextEditingController();
  final _queryDateController = TextEditingController();
  DateTime _queryDate = DateTime.now();

  /// API issue types (value sent to the server) paired with their UI labels.
  /// See docs/api/attendance-log.md §4a.
  static const List<MapEntry<String, String>> _issueTypes = [
    MapEntry('medical_issue', 'Medical Issue'),
    MapEntry('missing_clock_in', 'Missing Clock In'),
    MapEntry('missing_clock_out', 'Missing Clock Out'),
    MapEntry('late_arrival', 'Late Arrival'),
    MapEntry('wrong_time', 'Wrong Time'),
    MapEntry('other', 'Other'),
  ];

  static String _issueLabel(String value) => _issueTypes
      .firstWhere((e) => e.key == value,
          orElse: () => const MapEntry('other', 'Other'))
      .value;

  String _queryType = 'medical_issue';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!mounted) return;
      setState(() {});
    });
    _queryDateController.text = DateFormat('dd MMM yyyy').format(_queryDate);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _queryDetailsController.dispose();
    _queryDateController.dispose();
    super.dispose();
  }

  void _submitQuery() {
    if (_queryFormKey.currentState!.validate()) {
      context.read<AttendanceBloc>().add(
            RaiseIssue(
              type: _queryType,
              date: DateFormat('yyyy-MM-dd').format(_queryDate),
              details: _queryDetailsController.text.trim(),
            ),
          );
    }
  }

  /// Resets the issue form after a successful submission.
  void _resetQueryForm() {
    setState(() {
      _queryDetailsController.clear();
      _queryDate = DateTime.now();
      _queryDateController.text = DateFormat('dd MMM yyyy').format(_queryDate);
      _queryType = 'medical_issue';
    });
  }

  void _showSnack(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(error ? Icons.error_outline : Icons.check_circle,
                color: Colors.white),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'AirbnbCereal'),
              ),
            ),
          ],
        ),
        backgroundColor: error ? AppColors.error : AppColors.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  Future<void> _selectQueryDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _queryDate,
      firstDate: DateTime(2025),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _queryDate) {
      setState(() {
        _queryDate = picked;
        _queryDateController.text = DateFormat(
          'dd MMM yyyy',
        ).format(_queryDate);
      });
    }
  }

  void _showAttendanceActions(dynamic log) {
    final dateStr = DateFormat('dd MMM yyyy').format(log.date as DateTime);
    final checkInStr = log.checkIn != null
        ? DateFormat('hh:mm a').format(log.checkIn as DateTime)
        : '--';
    final checkOutStr = log.checkOut != null
        ? DateFormat('hh:mm a').format(log.checkOut as DateTime)
        : '--';

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (BuildContext context) {
        final size = MediaQuery.of(context).size;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          padding: EdgeInsets.fromLTRB(
            24,
            16,
            24,
            24 + MediaQuery.of(context).padding.bottom,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                "Options for $dateStr",
                style: TextStyle(
                  fontFamily: "AirbnbCereal",
                  fontSize: size.width * 0.045,
                  fontWeight: FontWeight.w500,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: const Icon(LucideIcons.log_in, color: Colors.blue),
                title: const Text(
                  "View Check-In Details",
                  style: TextStyle(fontFamily: 'AirbnbCereal'),
                ),
                subtitle: Text(
                  "Clocked in at $checkInStr",
                  style: const TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCheckInDetails(log);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.log_out, color: Colors.indigo),
                title: const Text(
                  "View Check-Out Details",
                  style: TextStyle(fontFamily: 'AirbnbCereal'),
                ),
                subtitle: Text(
                  "Clocked out at $checkOutStr",
                  style: const TextStyle(
                    fontFamily: 'AirbnbCereal',
                    fontSize: 12,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showCheckOutDetails(log);
                },
              ),
              ListTile(
                leading: const Icon(LucideIcons.circle, color: Colors.orange),
                title: const Text(
                  "Raise Correction Query",
                  style: TextStyle(fontFamily: 'AirbnbCereal'),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _tabController.animateTo(1);
                  setState(() {
                    _queryDate = log.date as DateTime;
                    _queryDateController.text = DateFormat(
                      'dd MMM yyyy',
                    ).format(_queryDate);
                    _queryType = 'wrong_time';
                    _queryDetailsController.text =
                        "Issue regarding shift hours on $dateStr. Registered check-in: $checkInStr, check-out: $checkOutStr.";
                  });
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showCheckInDetails(dynamic log) {
    final dateStr = DateFormat('dd MMM yyyy').format(log.date as DateTime);
    final checkInStr = log.checkIn != null
        ? DateFormat('hh:mm a').format(log.checkIn as DateTime)
        : '--';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.log_in, color: Colors.green),
              SizedBox(width: 10),
              Text(
                "Check-In Details",
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Date", dateStr),
              _buildDetailRow("Time", checkInStr),
              _buildDetailRow(
                "Location",
                "Verified Work Location (Office GPS Coords)",
              ),
              _buildDetailRow("Status", log.status as String),
              const SizedBox(height: 10),
              const Text(
                "Selfie Verification",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image, color: Colors.grey, size: 32),
                    SizedBox(height: 6),
                    Text(
                      "Verified Photo",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showCheckOutDetails(dynamic log) {
    final dateStr = DateFormat('dd MMM yyyy').format(log.date as DateTime);
    final checkOutStr = log.checkOut != null
        ? DateFormat('hh:mm a').format(log.checkOut as DateTime)
        : '--';
    final hrsStr = log.workedHours != null ? '${log.workedHours} hrs' : '--';

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Row(
            children: [
              Icon(LucideIcons.log_out, color: Colors.red),
              SizedBox(width: 10),
              Text(
                "Check-Out Details",
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Date", dateStr),
              _buildDetailRow("Time", checkOutStr),
              _buildDetailRow(
                "Location",
                "Verified Work Location (Office GPS Coords)",
              ),
              _buildDetailRow("Shift Hours", hrsStr),
              const SizedBox(height: 10),
              const Text(
                "Selfie Verification",
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              const SizedBox(height: 6),
              Container(
                height: 120,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(LucideIcons.image, color: Colors.grey, size: 32),
                    SizedBox(height: 6),
                    Text(
                      "Verified Photo",
                      style: TextStyle(
                        color: Colors.grey,
                        fontSize: 12,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text(
                "Close",
                style: TextStyle(
                  fontFamily: 'AirbnbCereal',
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.grey,
                fontWeight: FontWeight.bold,
                fontFamily: 'AirbnbCereal',
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                color: Colors.black87,
                fontFamily: 'AirbnbCereal',
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: const Color(0xFFF5F6FA),
      appBar: AppAppBar(
        title: 'Attendance log',
        showBack: true,
        actions: [
          TextButton.icon(
            onPressed: () => context.push(AppRoutes.leave),
            icon: const Icon(LucideIcons.plane_takeoff,
                size: 16, color: AppColors.primary),
            label: const Text(
              'Leave',
              style: TextStyle(
                fontFamily: 'AirbnbCereal',
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
      body: BlocConsumer<AttendanceBloc, AttendanceState>(
        listenWhen: (prev, curr) =>
            curr is AttendanceIssueSubmitSuccess ||
            curr is AttendanceIssueSubmitFailure,
        listener: (context, state) {
          if (state is AttendanceIssueSubmitSuccess) {
            _resetQueryForm();
            _showSnack('Issue ${state.issue.code} submitted successfully!');
          } else if (state is AttendanceIssueSubmitFailure) {
            _showSnack(state.errorMessage, error: true);
          }
        },
        builder: (context, state) {
          if (state is AttendanceLoading) {
            return const Center(child: LoadingWidget());
          }
          if (state is AttendanceError) {
            return EmptyState(
              icon: Icons.error_outline,
              title: state.message,
              buttonLabel: 'Retry',
              onButtonTap: () => context.read<AttendanceBloc>().add(
                const FetchAttendanceLog(),
              ),
            );
          }

          // Safe extract of state data
          final loaded = state is AttendanceLoaded ? state : null;
          final logs = loaded?.logs ?? const <AttendanceLogEntity>[];
          final summary = loaded?.summary;
          final issues = loaded?.issues ?? const <AttendanceIssueEntity>[];
          final isCheckedIn = loaded?.isCheckedIn ?? false;
          final isSubmittingIssue = loaded?.isSubmittingIssue ?? false;

          final hoursWeek = summary != null
              ? '${summary.hoursWorked.toStringAsFixed(1)} / ${summary.hoursTarget.toStringAsFixed(0)}h'
              : '-- / --';
          final attRate = summary != null
              ? '${summary.attendanceRate.toStringAsFixed(1)}%'
              : '--';
          final lateCount =
              summary != null ? '${summary.lateArrivals} arrivals' : '--';
          final dutyDays = summary != null
              ? '${summary.dutyDaysPresent} / ${summary.dutyDaysTotal}d'
              : '--';

          return NestedScrollView(
            headerSliverBuilder:
                (BuildContext context, bool innerBoxIsScrolled) {
                  return <Widget>[
                    SliverToBoxAdapter(
                      child: Column(
                        children: [
                          // Statistics summary card
                          Container(
                            color: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.width * 0.03,
                            ),
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: Colors.grey.shade100),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatItem(
                                          "Hours This Week",
                                          hoursWeek,
                                          LucideIcons.calendar_clock,
                                          Colors.blue,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: _buildStatItem(
                                            "Attendance Rate",
                                            attRate,
                                            LucideIcons.clock,
                                            AppColors.primary,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  const Divider(
                                    color: Color(0xFFEEEEEE),
                                    height: 1,
                                  ),
                                  const SizedBox(height: 12),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _buildStatItem(
                                          "Late Arrivals",
                                          lateCount,
                                          LucideIcons.timer,
                                          Colors.red,
                                          iconSize: 26,
                                        ),
                                      ),
                                      Container(
                                        width: 1,
                                        height: 40,
                                        color: Colors.grey.shade300,
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.only(
                                            left: 16,
                                          ),
                                          child: _buildStatItem(
                                            "Duty Days",
                                            dutyDays,
                                            LucideIcons.calendar_days,
                                            Colors.green,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),

                          // Custom Sliding Tabs
                          Container(
                            color: Colors.white,
                            padding: EdgeInsets.symmetric(
                              horizontal: size.width * 0.04,
                              vertical: size.width * 0.02,
                            ),
                            child: SlidingTabs(
                              selectedIndex: _tabController.index,
                              onTabChanged: (index) {
                                _tabController.animateTo(index);
                              },
                              tabs: const [
                                "Attendance Log",
                                "Attendance Issues",
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ];
                },
            body: TabBarView(
              controller: _tabController,
              children: [
                _buildAttendanceLogTab(size, isCheckedIn, logs),
                _buildQueriesTab(size, issues, isSubmittingIssue),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatItem(
    String label,
    String value,
    IconData icon,
    Color color, {
    double iconSize = 22,
  }) {
    return Row(
      children: [
        SizedBox(
          width: 26,
          child: Center(
            child: Icon(icon, color: color, size: iconSize),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11,
                  color: Colors.grey,
                  fontWeight: FontWeight.w500,
                  fontFamily: "AirbnbCereal",
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                  fontFamily: "AirbnbCereal",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // Maps the API `status` enum to a badge colour / label.
  Color _logStatusColor(String status) {
    switch (status) {
      case 'on_time':
        return AppColors.success;
      case 'late':
        return Colors.orange;
      case 'absent':
        return Colors.red;
      case 'present':
        return AppColors.primary;
      case 'upcoming':
        return Colors.blueGrey;
      case 'off':
      default:
        return Colors.grey;
    }
  }

  String _logStatusLabel(String status) {
    switch (status) {
      case 'on_time':
        return 'On Time';
      case 'late':
        return 'Late Arrival';
      case 'absent':
        return 'Absent';
      case 'present':
        return 'On Duty';
      case 'upcoming':
        return 'Upcoming';
      case 'off':
        return 'Off Day';
      default:
        return status;
    }
  }

  Color _issueStatusColor(String status) {
    switch (status) {
      case 'approved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      case 'pending':
      default:
        return Colors.amber;
    }
  }

  Widget _buildAttendanceLogTab(
    Size size,
    bool isCheckedIn,
    List<dynamic> logs,
  ) {
    return ListView.builder(
      padding: EdgeInsets.all(size.width * 0.04),
      itemCount: logs.length + 1,
      itemBuilder: (context, index) {
        if (index == 0) {
          return GestureDetector(
            onTap: () async {
              if (!isCheckedIn) {
                await context.push(
                  AppRoutes.uniformVerification,
                  extra: context.read<AttendanceBloc>(),
                );
              } else {
                await context.push(
                  AppRoutes.checkInOut,
                  extra: {
                    'isCheckingIn': !isCheckedIn,
                    'attendanceBloc': context.read<AttendanceBloc>(),
                  },
                );
              }
              if (context.mounted) {
                context.read<AttendanceBloc>().add(const FetchAttendanceLog());
              }
            },
            child: Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: EdgeInsets.all(size.width * 0.04),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFEFF1F6)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.015),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCheckedIn
                          ? const Color(0xFFE6F9F2)
                          : const Color(0xFFFEF3C7),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isCheckedIn
                          ? LucideIcons.shield_check
                          : LucideIcons.shield_alert,
                      color: isCheckedIn
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isCheckedIn
                              ? "You are Logged In"
                              : "You are Logged Out",
                          style: TextStyle(
                            fontFamily: "AirbnbCereal",
                            fontSize: size.width * 0.038,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          "Tap to Log On Duty now",
                          style: TextStyle(
                            fontFamily: "AirbnbCereal",
                            fontSize: size.width * 0.028,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: () async {
                      if (!isCheckedIn) {
                        await context.push(
                          AppRoutes.uniformVerification,
                          extra: context.read<AttendanceBloc>(),
                        );
                      } else {
                        await context.push(
                          AppRoutes.checkInOut,
                          extra: {
                            'isCheckingIn': !isCheckedIn,
                            'attendanceBloc': context.read<AttendanceBloc>(),
                          },
                        );
                      }
                      if (context.mounted) {
                        context.read<AttendanceBloc>().add(
                          const FetchAttendanceLog(),
                        );
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isCheckedIn
                          ? Colors.orange
                          : AppColors.primary,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      minimumSize: const Size(0, 0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      isCheckedIn ? "Log Off Duty" : "Log On Duty",
                      style: const TextStyle(
                        fontFamily: 'AirbnbCereal',
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        final log = logs[index - 1];
        final formattedDate = DateFormat(
          'dd MMM yyyy',
        ).format(log.date as DateTime);
        final checkInStr = log.checkIn != null
            ? DateFormat('hh:mm a').format(log.checkIn as DateTime)
            : '--';
        final checkOutStr = log.checkOut != null
            ? DateFormat('hh:mm a').format(log.checkOut as DateTime)
            : '--';
        final workedHoursStr = log.workedHours != null
            ? '${log.workedHours} hrs'
            : '0.0 hrs';

        final statusColor = _logStatusColor(log.status as String);

        return Card(
          elevation: 0,
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: Colors.grey.shade100),
          ),
          child: InkWell(
            onTap: () => _showAttendanceActions(log),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                            fontFamily: "AirbnbCereal",
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            const Icon(
                              LucideIcons.log_in,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "In: $checkInStr",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: "AirbnbCereal",
                              ),
                            ),
                            const SizedBox(width: 15),
                            const Icon(
                              LucideIcons.log_out,
                              size: 13,
                              color: Colors.grey,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              "Out: $checkOutStr",
                              style: const TextStyle(
                                fontSize: 12,
                                color: Colors.grey,
                                fontFamily: "AirbnbCereal",
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            workedHoursStr,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                              fontFamily: "AirbnbCereal",
                            ),
                          ),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              _logStatusLabel(log.status as String),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                                fontFamily: "AirbnbCereal",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 8),
                      Icon(
                        Icons.chevron_right,
                        color: Colors.grey.shade400,
                        size: 20,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildQueriesTab(
    Size size,
    List<AttendanceIssueEntity> issues,
    bool isSubmitting,
  ) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: EdgeInsets.all(size.width * 0.04),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Query Form Container
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            padding: EdgeInsets.all(size.width * 0.045),
            child: Form(
              key: _queryFormKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "Report an Attendance Issue",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                      fontFamily: "AirbnbCereal",
                    ),
                  ),
                  const SizedBox(height: 12),
                  CustomDropdown<String>(
                    value: _queryType,
                    items: _issueTypes.map((e) => e.key).toList(),
                    width: double.infinity,
                    buttonWidth: size.width * 0.8,
                    buttonColor: Colors.grey.shade50,
                    icon: const Icon(Icons.arrow_drop_down, color: Colors.grey),
                    itemBuilder: (val, isSelected) {
                      return Text(
                        _issueLabel(val),
                        style: const TextStyle(
                          fontFamily: 'AirbnbCereal',
                          fontSize: 13,
                          color: Colors.black87,
                        ),
                      );
                    },
                    onChanged: (String? newValue) {
                      if (newValue != null) {
                        setState(() {
                          _queryType = newValue;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _queryDateController,
                    readOnly: true,
                    onTap: () => _selectQueryDate(context),
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: "Select Date",
                      prefixIcon: const Icon(
                        LucideIcons.calendar,
                        color: Colors.grey,
                        size: 18,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  TextFormField(
                    controller: _queryDetailsController,
                    maxLines: 3,
                    style: const TextStyle(
                      fontFamily: 'AirbnbCereal',
                      fontSize: 13,
                      color: Colors.black87,
                    ),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: Colors.grey.shade50,
                      hintText: "Provide details about the issue...",
                      prefixIcon: const Icon(
                        LucideIcons.message_square,
                        color: Colors.grey,
                        size: 18,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 12,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: BorderSide(color: Colors.grey.shade200),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(color: AppColors.primary),
                      ),
                    ),
                    validator: (value) =>
                        value!.trim().isEmpty ? 'Enter details' : null,
                  ),
                  const SizedBox(height: 15),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isSubmitting ? null : _submitQuery,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        disabledBackgroundColor: AppColors.primary.withOpacity(
                          0.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: isSubmitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              "Submit",
                              style: TextStyle(
                                fontFamily: 'AirbnbCereal',
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            "Attendance Issue Log",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
              fontFamily: "AirbnbCereal",
            ),
          ),
          const SizedBox(height: 10),

          // Issues List
          if (issues.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Column(
                  children: [
                    Icon(
                      LucideIcons.inbox,
                      color: Colors.grey.shade300,
                      size: 40,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "No attendance issues raised yet",
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade500,
                        fontFamily: "AirbnbCereal",
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: issues.length,
              itemBuilder: (context, index) {
                final issue = issues[index];
                final statusColor = _issueStatusColor(issue.status);
                final dateStr = issue.date != null
                    ? DateFormat('dd MMM yyyy').format(issue.date!)
                    : '--';

                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.015),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            issue.code,
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.primary,
                              fontFamily: "AirbnbCereal",
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 3,
                            ),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              issue.status[0].toUpperCase() +
                                  issue.status.substring(1),
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: statusColor,
                                fontFamily: "AirbnbCereal",
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "${_issueLabel(issue.type)} • $dateStr",
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                          fontFamily: "AirbnbCereal",
                        ),
                      ),
                      if (issue.details.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(
                          issue.details,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                            fontFamily: "AirbnbCereal",
                          ),
                        ),
                      ],
                      if ((issue.hrResponse ?? '').isNotEmpty) ...[
                        const Divider(height: 20),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade100),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "Response from HR/Admin:",
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black54,
                                  fontFamily: "AirbnbCereal",
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                issue.hrResponse!,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey.shade800,
                                  fontFamily: "AirbnbCereal",
                                ),
                              ),
                              if ((issue.decidedBy ?? '').isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  "— ${issue.decidedBy}",
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontStyle: FontStyle.italic,
                                    color: Colors.grey.shade500,
                                    fontFamily: "AirbnbCereal",
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
