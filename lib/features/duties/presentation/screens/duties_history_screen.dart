import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:presshop_enterprise/config/routes/app_router.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/features/duties/data/models/duty_shift_model.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import '../../../../common/widgets/empty_state.dart';
import '../../../../common/widgets/loading_widget.dart';
import '../../../../config/di/injection.dart';
import '../../domain/entities/duty_entities.dart';
import '../bloc/duties_bloc.dart';

class DutiesHistoryScreen extends StatelessWidget {
  const DutiesHistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<DutiesBloc>()
        ..add(const FetchDutyHistory(range: DutyHistoryRange.lastYear)),
      child: const _DutiesHistoryView(),
    );
  }
}

class _DutiesHistoryView extends StatefulWidget {
  const _DutiesHistoryView();

  @override
  State<_DutiesHistoryView> createState() => _DutiesHistoryViewState();
}

class _DutiesHistoryViewState extends State<_DutiesHistoryView> {
  DutyHistoryRange _selectedRange = DutyHistoryRange.lastYear;

  String _fmtMinutes(int m) {
    if (m <= 0) return "0h 0m";
    return "${m ~/ 60}h ${m % 60}m";
  }

  String _fmtTime(DateTime? d) =>
      d == null ? '--' : DateFormat('h:mm a').format(d.toLocal());

  String _fmtHours(double h) =>
      h == h.roundToDouble() ? "${h.round()}h" : "${h.toStringAsFixed(1)}h";

  // The detail screen consumes the legacy DutyShiftHistory; build one from the
  // lean API row (fields the API doesn't provide are left empty and the detail
  // screen hides them).
  DutyShiftHistory _rowToHistory(DutyHistoryRowEntity r) => DutyShiftHistory(
        id: '',
        date: r.date ?? DateTime.now(),
        checkInTime: _fmtTime(r.start),
        checkOutTime: _fmtTime(r.end),
        duration: _fmtMinutes(r.durationMinutes),
        durationHours: r.durationMinutes / 60.0,
        locationName: r.site,
        locationAddress: '',
        supervisorName: '',
        supervisorPhone: '',
        uniformStatus: '',
        completedTasks: const [],
        checkInSelfie: '',
        checkOutSelfie: '',
        notes: '',
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'late':
        return const Color(0xFF9A6411);
      case 'present':
        return AppColors.primary;
      case 'completed':
      default:
        return const Color(0xFF127A45);
    }
  }

  Color _statusBg(String status) {
    switch (status) {
      case 'late':
        return const Color(0xFFFDF3E2);
      case 'present':
        return const Color(0xFFEAF1FE);
      case 'completed':
      default:
        return const Color(0xFFEAF5EE);
    }
  }

  String _statusLabel(String status) {
    switch (status) {
      case 'late':
        return 'Late';
      case 'present':
        return 'On Duty';
      case 'completed':
      default:
        return 'Completed';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: const AppAppBar(
        title: "Duties history",
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: SafeArea(
        child: BlocBuilder<DutiesBloc, DutiesState>(
          builder: (context, state) {
            if (state is DutiesHistoryLoading || state is DutiesInitial) {
              return const Center(child: LoadingWidget());
            }
            if (state is DutiesHistoryError) {
              return EmptyState(
                icon: Icons.error_outline,
                title: state.message,
                buttonLabel: 'Retry',
                onButtonTap: () => context
                    .read<DutiesBloc>()
                    .add(FetchDutyHistory(range: _selectedRange)),
              );
            }

            final history =
                state is DutiesHistoryLoaded ? state.history : null;
            final summary = history?.summary;
            final rows = history?.rows ?? const <DutyHistoryRowEntity>[];

            final avgShift =
                summary != null ? _fmtMinutes(summary.avgShiftMinutes) : "0h 0m";
            final totalHrs =
                summary != null ? _fmtHours(summary.totalHours) : "0h";
            final shiftsDone = (summary?.shiftsDone ?? rows.length).toString();

            return Column(
              children: [
                _buildStatsCard(avgShift, totalHrs, shiftsDone),
                Expanded(
                  child: rows.isEmpty
                      ? _buildEmptyState()
                      : ListView.builder(
                          padding: EdgeInsets.symmetric(
                            horizontal: 16.w,
                            vertical: 10.h,
                          ),
                          itemCount: rows.length,
                          itemBuilder: (context, index) =>
                              _buildHistoryItem(rows[index]),
                        ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildStatsCard(String avgShift, String totalHrs, String shiftsDone) {
    return Container(
      margin: EdgeInsets.all(16.w),
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 32.w,
                    height: 32.w,
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF1FE),
                      borderRadius: BorderRadius.circular(10.r),
                    ),
                    child: Icon(
                      LucideIcons.briefcase,
                      color: AppColors.primary,
                      size: 15.sp,
                    ),
                  ),
                  SizedBox(width: 10.w),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Duties Summary',
                        style: TextStyle(
                          color: const Color(0xFF0B0F1A),
                          fontSize: 13.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      Text(
                        'Based on selected filter',
                        style: TextStyle(
                          color: const Color(0xFF5A6373),
                          fontSize: 10.sp,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              // Filter Dropdown
              Container(
                padding: EdgeInsets.symmetric(horizontal: 10.w, vertical: 2.h),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10.r),
                  border: Border.all(color: const Color(0xFFE2E6EE)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.015),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<DutyHistoryRange>(
                    value: _selectedRange,
                    dropdownColor: Colors.white,
                    isDense: true,
                    icon: Icon(
                      Icons.keyboard_arrow_down,
                      color: const Color(0xFF5A6373),
                      size: 18.sp,
                    ),
                    style: TextStyle(
                      color: const Color(0xFF0B0F1A),
                      fontSize: 11.5.sp,
                      fontWeight: FontWeight.w800,
                      fontFamily: 'AirbnbCereal',
                    ),
                    onChanged: (DutyHistoryRange? newValue) {
                      if (newValue != null && newValue != _selectedRange) {
                        setState(() => _selectedRange = newValue);
                        context
                            .read<DutiesBloc>()
                            .add(FetchDutyHistory(range: newValue));
                      }
                    },
                    items: DutyHistoryRange.values
                        .map<DropdownMenuItem<DutyHistoryRange>>((range) {
                      return DropdownMenuItem<DutyHistoryRange>(
                        value: range,
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              LucideIcons.calendar,
                              size: 13.sp,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6.w),
                            Text(
                              range.label,
                              style: TextStyle(
                                color: const Color(0xFF0B0F1A),
                                fontSize: 11.5.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 16.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildStatItem(avgShift, 'Avg Shift'),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildStatItem(totalHrs, 'Total Hrs'),
              Container(width: 1, height: 24.h, color: const Color(0xFFE5E8EE)),
              _buildStatItem(shiftsDone, 'Shifts Done'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String value, String label) {
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
            fontSize: 9.5.sp,
            fontWeight: FontWeight.w500,
            fontFamily: 'AirbnbCereal',
          ),
        ),
      ],
    );
  }

  Widget _buildHistoryItem(DutyHistoryRowEntity shift) {
    final formattedDate =
        shift.date != null ? DateFormat('EEE, MMM d').format(shift.date!) : '--';

    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14.r),
        child: InkWell(
          borderRadius: BorderRadius.circular(14.r),
          onTap: () => context.push(
            AppRoutes.dutiesHistoryDetails,
            extra: _rowToHistory(shift),
          ),
          child: Padding(
            padding: EdgeInsets.all(12.w),
            child: Row(
              children: [
                Container(
                  width: 32.w,
                  height: 32.w,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F9),
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                  child: Icon(
                    LucideIcons.clock,
                    color: const Color(0xFF9AA2B1),
                    size: 14.sp,
                  ),
                ),
                SizedBox(width: 12.w),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        formattedDate,
                        style: TextStyle(
                          color: const Color(0xFF0B0F1A),
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w800,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Text(
                        '${_fmtTime(shift.start)} – ${_fmtTime(shift.end)}',
                        style: TextStyle(
                          color: const Color(0xFF9AA2B1),
                          fontSize: 10.5.sp,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                      SizedBox(height: 3.h),
                      Row(
                        children: [
                          Icon(
                            LucideIcons.map_pin,
                            size: 11.sp,
                            color: const Color(0xFF9AA2B1),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              shift.site,
                              style: TextStyle(
                                color: const Color(0xFF5A6373),
                                fontSize: 10.5.sp,
                                fontFamily: 'AirbnbCereal',
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF3F5F9),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _fmtMinutes(shift.durationMinutes),
                        style: TextStyle(
                          color: const Color(0xFF5A6373),
                          fontSize: 10.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                    SizedBox(height: 8.h),
                    Container(
                      padding: EdgeInsets.symmetric(
                        horizontal: 8.w,
                        vertical: 3.h,
                      ),
                      decoration: BoxDecoration(
                        color: _statusBg(shift.status),
                        borderRadius: BorderRadius.circular(6.r),
                      ),
                      child: Text(
                        _statusLabel(shift.status),
                        style: TextStyle(
                          color: _statusColor(shift.status),
                          fontSize: 9.sp,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            LucideIcons.calendar_x,
            color: const Color(0xFF9AA2B1),
            size: 48.sp,
          ),
          SizedBox(height: 12.h),
          Text(
            'No Shifts Found',
            style: TextStyle(
              color: const Color(0xFF0B0F1A),
              fontSize: 14.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            'Try choosing a broader date range filter.',
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 11.sp,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ],
      ),
    );
  }
}
