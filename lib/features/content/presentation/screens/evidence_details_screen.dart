import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:intl/intl.dart';
import 'package:dots_indicator/dots_indicator.dart';
import 'package:presshop_enterprise/core/errors/failures.dart';
import 'package:presshop_enterprise/common/widgets/app_app_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/network/api_client.dart';
import '../../../../common/widgets/loading_widget.dart';
import 'package:go_router/go_router.dart';
import '../../../../config/routes/app_router.dart';
import '../../data/models/enterprise_feed_model.dart';
import '../../../tasks/data/models/employee_task_model.dart';

class EvidenceDetailsScreen extends StatefulWidget {
  final EnterpriseFeedItem item;

  const EvidenceDetailsScreen({super.key, required this.item});

  @override
  State<EvidenceDetailsScreen> createState() => _EvidenceDetailsScreenState();
}

class _EvidenceDetailsScreenState extends State<EvidenceDetailsScreen> {
  int _currentMediaIndex = 0;

  String? _localStatusOverride;
  bool _isNavigating = false;

  Timer? _workTimer;
  String _workDuration = '';

  @override
  void initState() {
    super.initState();
    final status = _getUserAssignmentStatus();
    if (status == 'started' || status == 'in_progress' || status == 'ongoing') {
      _initWorkTimer();
    }
  }

  String get _taskId => widget.item.task.id;

  String _getUserAssignmentStatus() {
    if (_localStatusOverride != null)
      return _localStatusOverride!.toLowerCase();
    return widget.item.task.status.toLowerCase();
  }

  Future<void> _startTask() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: LoadingWidget()),
    );
    try {
      if (!mounted) return;
      Navigator.pop(context);
      setState(() => _localStatusOverride = 'started');
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'task_start_$_taskId',
          DateTime.now().toIso8601String(),
        );
      } catch (_) {}
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Task started successfully.')),
      );
      _initWorkTimer();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
  }

  Future<void> _completeTask() async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(child: LoadingWidget()),
    );
    try {
      final apiClient = getIt<ApiClient>();
      await apiClient.post(
        'enterprise/task-assignments/$_taskId/complete',
        data: {'completionNote': 'Photos uploaded, brief done.'},
      );
      if (!mounted) return;
      Navigator.pop(context);
      setState(() {
        _localStatusOverride = 'completed';
        _workDuration = '';
      });
      _workTimer?.cancel();
      try {
        final prefs = await SharedPreferences.getInstance();
        await prefs.remove('task_start_$_taskId');
      } catch (_) {}
      _showSuccessDialog();
    } catch (e) {
      if (mounted) {
        Navigator.pop(context);
        final String errorMsg = e is Failure ? e.message : e.toString();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $errorMsg')));
      }
    }
  }

  Future<void> _initWorkTimer() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final savedStart = prefs.getString('task_start_$_taskId');
      DateTime? startTime;
      if (savedStart != null) startTime = DateTime.tryParse(savedStart);
      startTime ??= DateTime.now();
      _startWorkTimer(startTime.toLocal());
    } catch (_) {}
  }

  void _startWorkTimer(DateTime startTime) {
    _workTimer?.cancel();
    _updateWorkDuration(startTime);
    _workTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() => _updateWorkDuration(startTime));
      } else {
        timer.cancel();
      }
    });
  }

  void _updateWorkDuration(DateTime startTime) {
    final diff = DateTime.now().difference(startTime);
    if (diff.isNegative) {
      _workDuration = '00:00:00';
      return;
    }
    String two(int n) => n.toString().padLeft(2, '0');
    _workDuration =
        '${two(diff.inHours)}:${two(diff.inMinutes % 60)}:${two(diff.inSeconds % 60)}';
  }

  void _showSuccessDialog() {
    final size = MediaQuery.of(context).size;
    showDialog(
      context: context,
      barrierDismissible: false,
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
                      'Task Completed Successfully',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: size.width * 0.04,
                        fontFamily: 'AirbnbCereal',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        Navigator.pop(context);
                      },
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
                          'assets/rabbits/rabbit_for_alert.png',
                          height: size.width * 0.30,
                          width: size.width * 0.35,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    SizedBox(width: size.width * 0.04),
                    Expanded(
                      child: Text(
                        'Your task has been marked as complete and logged successfully. Thank you.',
                        style: TextStyle(
                          color: Colors.black,
                          fontSize: size.width * 0.035,
                          fontFamily: 'AirbnbCereal',
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
                child: SizedBox(
                  width: double.infinity,
                  height: size.width * 0.12,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(ctx);
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(size.width * 0.03),
                      ),
                    ),
                    child: Text(
                      'OK',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: size.width * 0.04,
                        fontFamily: 'AirbnbCereal',
                        fontWeight: FontWeight.bold,
                      ),
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

  @override
  void dispose() {
    _workTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final firstContent = widget.item.content.isNotEmpty
        ? widget.item.content.first
        : null;
    final location =
        (firstContent?.captureAddressLine1 != null &&
            firstContent!.captureAddressLine1.isNotEmpty)
        ? firstContent.captureAddressLine1
        : 'Location Not Captured';
    final capturedAt =
        (firstContent?.capturedAt != null &&
            firstContent!.capturedAt.isNotEmpty)
        ? firstContent.capturedAt
        : (firstContent?.createdAt ?? widget.item.task.createdAt);
    final description = widget.item.task.description.isNotEmpty
        ? widget.item.task.description
        : (firstContent?.description ?? '');

    final status = _getUserAssignmentStatus();
    final isCompleted = status == 'completed';
    final isStarted =
        status == 'started' || status == 'in_progress' || status == 'ongoing';

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppAppBar(
        title: "Evidence Details",
        backgroundColor: Colors.white,
        showBack: true,
        elevation: 0,
        titleSpacing: 0,
        centerTitle: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _imageSlideshow(),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.item.task.title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w700,
                        color: Colors.black,
                      ),
                    ),
                    SizedBox(height: 8.h),
                    if (capturedAt.isNotEmpty)
                      Row(
                        children: [
                          SizedBox(
                            width: 20.w,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                "assets/icons/ic_clock.png",
                                height: 16.w,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _fmt('hh:mm a', capturedAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                          SizedBox(width: 12.w),
                          SizedBox(
                            width: 20.w,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                "assets/icons/ic_yearly_calendar.png",
                                height: 16.w,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Text(
                            _fmt('dd MMM yyyy', capturedAt),
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 8.h),
                    if (location.isNotEmpty)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            width: 20.w,
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: Image.asset(
                                "assets/icons/ic_location.png",
                                height: 18.w,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                          SizedBox(width: 4.w),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 11.sp,
                                color: Colors.grey[600],
                              ),
                            ),
                          ),
                        ],
                      ),
                    SizedBox(height: 12.h),
                    const Divider(color: Color(0xFFE0E0E0)),
                    SizedBox(height: 8.h),
                    if (description.isNotEmpty)
                      Text(
                        description,
                        textAlign: TextAlign.justify,
                        style: TextStyle(
                          fontSize: 12.sp,
                          color: Colors.black,
                          height: 1.5,
                        ),
                      ),
                    SizedBox(height: 16.h),
                    const Divider(color: Color(0xFFE0E0E0)),
                    SizedBox(height: 12.h),

                    // Working Time Tracker (visible when task is started)
                    if (isStarted && _workDuration.isNotEmpty) ...[
                      Container(
                        width: double.infinity,
                        margin: EdgeInsets.only(bottom: 12.h),
                        padding: EdgeInsets.symmetric(
                          horizontal: 14.w,
                          vertical: 10.h,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE8F0FE),
                          borderRadius: BorderRadius.circular(10.r),
                          border: Border.all(color: const Color(0xFFD2E3FC)),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.timer_outlined,
                              color: Color(0xFF1877F2),
                            ),
                            SizedBox(width: 8.w),
                            const Text(
                              "Time Worked:",
                              style: TextStyle(
                                fontFamily: 'AirbnbCereal',
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _workDuration,
                              style: const TextStyle(
                                fontFamily: 'AirbnbCereal',
                                fontWeight: FontWeight.w900,
                                fontSize: 16,
                                color: Color(0xFF1877F2),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    // Start Task / Complete Task  +  Manage Task
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: size.width * 0.14,
                            child: ElevatedButton(
                              onPressed: isCompleted
                                  ? null
                                  : (isStarted ? _completeTask : _startTask),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: isCompleted
                                    ? Colors.grey.shade400
                                    : (isStarted
                                          ? const Color(0xFF000000)
                                          : const Color(0xFF000000)),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: Text(
                                isCompleted
                                    ? 'Completed'
                                    : (isStarted
                                          ? 'Tap to Complete Task'
                                          : 'Tab to Start Task'),
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.038,
                                  fontFamily: 'AirbnbCereal',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: SizedBox(
                            height: size.width * 0.14,
                            child: ElevatedButton(
                              onPressed: _isNavigating
                                  ? null
                                  : () async {
                                      if (_isNavigating) return;
                                      setState(() => _isNavigating = true);
                                      final apiClient = getIt<ApiClient>();
                                      try {
                                        final response = await apiClient.get(
                                          'enterprise/tasks/$_taskId',
                                        );
                                        if (!mounted) return;
                                        if (response.statusCode == 200 &&
                                            response.data != null) {
                                          final raw = response.data;
                                          final data =
                                              (raw['data']
                                                  is Map<String, dynamic>)
                                              ? raw['data']
                                                    as Map<String, dynamic>
                                              : raw as Map<String, dynamic>;
                                          final task =
                                              EmployeeTaskModel.fromJson(data);
                                          if (context.mounted) {
                                            await context.push(
                                              AppRoutes.taskChat,
                                              extra: {
                                                'taskDetail': task,
                                                'roomId': _taskId,
                                              },
                                            );
                                          }
                                        }
                                      } catch (_) {}
                                      if (mounted)
                                        setState(() => _isNavigating = false);
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10.r),
                                ),
                              ),
                              child: Text(
                                'Manage Task',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.038,
                                  fontFamily: 'AirbnbCereal',
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 16.h),
                    Text(
                      "Tap Manage Tasks to upload photos, videos, scans, audio recordings, and evidence directly from the field. Chat with your office, track live updates, and stay connected to every assignment in real time.",
                      textAlign: TextAlign.justify,
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.black,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    SizedBox(height: 20.h),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _imageSlideshow() {
    if (widget.item.content.isEmpty) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Container(
          height: 200.w,
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(16.r),
          ),
          child: const Center(
            child: Icon(Icons.image_outlined, size: 40, color: Colors.grey),
          ),
        ),
      );
    }
    return Column(
      children: [
        SizedBox(
          height: 200.w,
          child: PageView.builder(
            itemCount: widget.item.content.length,
            onPageChanged: (value) =>
                setState(() => _currentMediaIndex = value),
            itemBuilder: (_, i) {
              final contentItem = widget.item.content[i];
              final imageUrl = contentItem.previewUrl;
              final showImage = _isDisplayableImage(contentItem);
              return Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16.r),
                  child: Stack(
                    children: [
                      showImage
                          ? Image.network(
                              imageUrl,
                              width: double.infinity,
                              height: 200.w,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) =>
                                  Container(color: Colors.grey[300]),
                            )
                          : Container(
                              width: double.infinity,
                              height: 200.w,
                              color: Colors.grey[300],
                              child: Center(
                                child: Icon(
                                  _evidenceTypeIcon(contentItem.evidenceType),
                                  size: 56.w,
                                  color: Colors.grey,
                                ),
                              ),
                            ),
                      if (showImage)
                        Image.asset(
                          "assets/images/watermark1.png",
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      Positioned(
                        right: 8.w,
                        top: 8.w,
                        child: Column(children: _getMediaCountList()),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.item.content.length > 1) ...[
          SizedBox(height: 12.h),
          DotsIndicator(
            dotsCount: widget.item.content.length,
            position: _currentMediaIndex,
            decorator: const DotsDecorator(
              color: Colors.grey,
              activeColor: AppColors.primaryLight,
            ),
          ),
        ],
      ],
    );
  }

  List<Widget> _getMediaCountList() {
    final contents = widget.item.content;
    final imageCount = contents
        .where((c) => c.evidenceType.toLowerCase() == 'image')
        .length;
    final videoCount = contents
        .where((c) => c.evidenceType.toLowerCase() == 'video')
        .length;
    final audioCount = contents
        .where((c) => c.evidenceType.toLowerCase() == 'audio')
        .length;
    final docCount = contents.where((c) {
      final t = c.evidenceType.toLowerCase();
      return t == 'doc' || t == 'document' || t == 'pdf';
    }).length;

    final List<Widget> list = [];
    if (imageCount > 0) list.add(_buildCountCard('image', imageCount));
    if (videoCount > 0) {
      if (list.isNotEmpty) list.add(SizedBox(height: 6.h));
      list.add(_buildCountCard('video', videoCount));
    }
    if (audioCount > 0) {
      if (list.isNotEmpty) list.add(SizedBox(height: 6.h));
      list.add(_buildCountCard('audio', audioCount));
    }
    if (docCount > 0) {
      if (list.isNotEmpty) list.add(SizedBox(height: 6.h));
      list.add(_buildCountCard('document', docCount));
    }
    return list;
  }

  Widget _buildCountCard(String type, int count) {
    return Container(
      width: 44.w,
      padding: EdgeInsets.symmetric(vertical: 4.h),
      decoration: BoxDecoration(
        color: const Color(0xFF3F4E4C).withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(8.r),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            "$count",
            style: TextStyle(
              fontSize: 11.sp,
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(width: 3.w),
          Image.asset(
            type == 'image'
                ? 'assets/icons/ic_camera_publish.png'
                : type == 'video'
                ? 'assets/icons/ic_v_cam.png'
                : type == 'audio'
                ? 'assets/icons/new_audio.png'
                : 'assets/icons/doc_icon.png',
            color: Colors.white,
            height: type == 'image' ? 10.w : 14.w,
            width: type == 'image' ? 10.w : 14.w,
          ),
        ],
      ),
    );
  }

  bool _isDisplayableImage(EnterpriseFeedContent content) {
    final t = content.evidenceType.toLowerCase();
    return t == 'image' && content.previewUrl.isNotEmpty;
  }

  IconData _evidenceTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'video':
        return Icons.videocam_outlined;
      case 'audio':
        return Icons.mic_outlined;
      case 'doc':
      case 'document':
      case 'pdf':
        return Icons.description_outlined;
      default:
        return Icons.image_outlined;
    }
  }

  String _fmt(String format, String iso) {
    try {
      return DateFormat(format).format(DateTime.parse(iso).toLocal());
    } catch (_) {
      return '';
    }
  }
}
