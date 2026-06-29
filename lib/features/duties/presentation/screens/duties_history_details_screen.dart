import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import 'package:presshop_enterprise/features/duties/data/models/duty_shift_model.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';

class DutiesHistoryDetailsScreen extends StatelessWidget {
  final DutyShiftHistory shift;

  const DutiesHistoryDetailsScreen({super.key, required this.shift});

  void _showToast(BuildContext context, String message) {
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

  @override
  Widget build(BuildContext context) {
    final formattedDate = DateFormat('EEEE, MMMM d, yyyy').format(shift.date);

    return Scaffold(
      backgroundColor: const Color(0xFFF9FAFC),
      appBar: const AppAppBar(
        title: "Shift details",
        elevation: 0,
        centerTitle: false,
        titleSpacing: 0,
        showBack: true,
      ),
      body: SafeArea(
        child: ListView(
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
          children: [
            // Date & ID Header Card
            _buildHeaderCard(formattedDate),
            SizedBox(height: 16.h),

            // Time & Duration Card
            _buildTimelineCard(context),

            // Location & Supervisor Card (only when we have those details)
            if (shift.locationAddress.isNotEmpty ||
                shift.supervisorName.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildLocationSupervisorCard(context),
            ],

            // Selfie Verification Card
            if (shift.checkInSelfie.isNotEmpty ||
                shift.checkOutSelfie.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildSelfieVerificationCard(context),
            ],

            // Uniform Validation Card
            if (shift.uniformStatus.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildUniformChecklistCard(),
            ],

            // Tasks Completed Card
            if (shift.completedTasks.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildCompletedTasksCard(),
            ],

            // Handover / Shift Notes Card
            if (shift.notes.isNotEmpty) ...[
              SizedBox(height: 16.h),
              _buildNotesCard(),
            ],
            SizedBox(height: 24.h),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(String formattedDate) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF5EE),
                  borderRadius: BorderRadius.circular(6.r),
                ),
                child: Text(
                  "Completed",
                  style: TextStyle(
                    color: const Color(0xFF127A45),
                    fontSize: 10.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
              ),
              if (shift.id.isNotEmpty)
                Text(
                  shift.id,
                  style: TextStyle(
                    color: const Color(0xFF9AA2B1),
                    fontSize: 11.sp,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
            ],
          ),
          SizedBox(height: 10.h),
          Text(
            formattedDate,
            style: TextStyle(
              color: const Color(0xFF0B0F1A),
              fontSize: 16.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'AirbnbCereal',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SHIFT DURATION",
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              // Left side visual timeline
              Column(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF127A45), size: 12),
                  Container(
                    width: 2.w,
                    height: 36.h,
                    color: const Color(0xFFE5E8EE),
                  ),
                  const Icon(Icons.circle, color: Color(0xFFFF3B30), size: 12),
                ],
              ),
              SizedBox(width: 14.w),
              // Timeline details
              Expanded(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Logged On",
                              style: TextStyle(
                                color: const Color(0xFF5A6373),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                            Text(
                              shift.checkInTime,
                              style: TextStyle(
                                color: const Color(0xFF0B0F1A),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "GPS Match: 100%",
                          style: TextStyle(
                            color: const Color(0xFF127A45),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 12.h),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              "Logged Off",
                              style: TextStyle(
                                color: const Color(0xFF5A6373),
                                fontSize: 11.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                            Text(
                              shift.checkOutTime,
                              style: TextStyle(
                                color: const Color(0xFF0B0F1A),
                                fontSize: 13.sp,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'AirbnbCereal',
                              ),
                            ),
                          ],
                        ),
                        Text(
                          "GPS Match: 100%",
                          style: TextStyle(
                            color: const Color(0xFF127A45),
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFEFF1F5)),
          SizedBox(height: 10.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                "Total Worked Hours",
                style: TextStyle(
                  color: const Color(0xFF5A6373),
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
              Text(
                shift.duration,
                style: TextStyle(
                  color: AppColors.primary,
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w800,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLocationSupervisorCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SITE & SUPERVISOR",
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 14.h),

          // Site Row
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: EdgeInsets.all(10.w),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF1FE),
                  borderRadius: BorderRadius.circular(10.r),
                ),
                child: Icon(
                  LucideIcons.building,
                  color: AppColors.primary,
                  size: 20.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.locationName,
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      shift.locationAddress,
                      style: TextStyle(
                        color: const Color(0xFF5A6373),
                        fontSize: 11.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          SizedBox(height: 14.h),
          const Divider(height: 1, color: Color(0xFFEFF1F5)),
          SizedBox(height: 14.h),

          // Supervisor Row
          Row(
            children: [
              Container(
                width: 40.w,
                height: 40.w,
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F9),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFE2E6EE)),
                ),
                child: Icon(
                  LucideIcons.user,
                  color: const Color(0xFF9AA2B1),
                  size: 18.sp,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift.supervisorName,
                      style: TextStyle(
                        color: const Color(0xFF0B0F1A),
                        fontSize: 13.sp,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    SizedBox(height: 2.h),
                    Text(
                      "Site Supervisor",
                      style: TextStyle(
                        color: const Color(0xFF9AA2B1),
                        fontSize: 10.5.sp,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFEAF5EE),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10.r),
                  ),
                ),
                icon: const Icon(
                  LucideIcons.phone,
                  color: Color(0xFF127A45),
                  size: 16,
                ),
                onPressed: () => _showToast(
                  context,
                  "Calling supervisor: ${shift.supervisorPhone}",
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieVerificationCard(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "SELFIE VERIFICATION",
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 14.h),
          Row(
            children: [
              Expanded(
                child: _buildSelfieBox(
                  context,
                  title: "Log On Selfie",
                  time: shift.checkInTime,
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: _buildSelfieBox(
                  context,
                  title: "Log Off Selfie",
                  time: shift.checkOutTime,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSelfieBox(
    BuildContext context, {
    required String title,
    required String time,
  }) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFC),
        borderRadius: BorderRadius.circular(12.r),
        border: Border.all(color: const Color(0xFFE2E6EE)),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: const Color(0xFF0B0F1A),
              fontSize: 11.sp,
              fontWeight: FontWeight.bold,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 8.h),

          // Custom premium mockup of verified selfie
          Container(
            height: 90.h,
            width: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8.r),
              border: Border.all(color: const Color(0xFFEFF1F5)),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/ic_black_rabbit.png',
                  height: 48.h,
                  width: 48.w,
                  fit: BoxFit.contain,
                  opacity: const AlwaysStoppedAnimation(0.08),
                  errorBuilder: (context, error, stackTrace) => Icon(
                    LucideIcons.camera,
                    color: const Color(0xFF9AA2B1).withValues(alpha: 0.2),
                    size: 32.sp,
                  ),
                ),
                Positioned(
                  top: 8.h,
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 6.w,
                      vertical: 2.h,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEAF5EE),
                      borderRadius: BorderRadius.circular(4.r),
                    ),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.verified,
                          color: Color(0xFF127A45),
                          size: 10,
                        ),
                        SizedBox(width: 2.w),
                        Text(
                          "VERIFIED",
                          style: TextStyle(
                            color: const Color(0xFF127A45),
                            fontSize: 7.5.sp,
                            fontWeight: FontWeight.w800,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  bottom: 8.h,
                  child: Text(
                    time,
                    style: TextStyle(
                      color: const Color(0xFF5A6373),
                      fontSize: 10.sp,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUniformChecklistCard() {
    // Check elements
    final checklist = [
      'Cap Checked',
      'Badge / ID Card Checked',
      'Duty Boots Checked',
      'Security Belt Checked',
      'High-Visibility Vest Checked',
    ];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "UNIFORM VALIDATION STATUS",
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 10.h),
          Column(
            children: checklist
                .map(
                  (item) => Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.h),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.check_circle,
                          color: Color(0xFF127A45),
                          size: 16,
                        ),
                        SizedBox(width: 8.w),
                        Text(
                          item,
                          style: TextStyle(
                            color: const Color(0xFF0B0F1A),
                            fontSize: 12.sp,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ],
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCompletedTasksCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "COMPLETED TASKS DURING SHIFT",
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 10.h),
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shift.completedTasks.length,
            itemBuilder: (context, index) {
              final task = shift.completedTasks[index];
              return Padding(
                padding: EdgeInsets.symmetric(vertical: 6.h),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Color(0xFFEAF5EE),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check,
                        color: Color(0xFF127A45),
                        size: 12,
                      ),
                    ),
                    SizedBox(width: 10.w),
                    Expanded(
                      child: Text(
                        task,
                        style: TextStyle(
                          color: const Color(0xFF0B0F1A),
                          fontSize: 12.5.sp,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNotesCard() {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16.r),
        border: Border.all(color: const Color(0xFFEFF1F5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "HANDOVER / SHIFT NOTES",
            style: TextStyle(
              color: const Color(0xFF9AA2B1),
              fontSize: 9.sp,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.8,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 10.h),
          Text(
            shift.notes,
            style: TextStyle(
              color: const Color(0xFF5A6373),
              fontSize: 12.sp,
              fontFamily: 'AirbnbCereal',
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
