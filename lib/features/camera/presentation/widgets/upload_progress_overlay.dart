import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../../../core/constants/app_colors.dart';
import '../../utils/upload_progress_notifier.dart';

/// Global, always-on-top banner that reflects [UploadProgressNotifier] state.
/// Mirrors the legacy app's UploadProgressWidget (uploading → complete → failed
/// with retry) and floats over every screen while an evidence upload runs.
class UploadProgressOverlay extends StatefulWidget {
  const UploadProgressOverlay({super.key});

  @override
  State<UploadProgressOverlay> createState() => _UploadProgressOverlayState();
}

class _UploadProgressOverlayState extends State<UploadProgressOverlay>
    with SingleTickerProviderStateMixin {
  final UploadProgressNotifier _notifier = UploadProgressNotifier.instance;
  late final AnimationController _pulse;
  Timer? _autoDismiss;
  bool _retrying = false;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _notifier.addListener(_onChange);
  }

  void _onChange() {
    // Auto-dismiss a little after a successful upload.
    if (_notifier.status == UploadStatus.success) {
      _autoDismiss?.cancel();
      _autoDismiss = Timer(const Duration(seconds: 3), () {
        if (mounted) _notifier.reset();
      });
    }
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _autoDismiss?.cancel();
    _notifier.removeListener(_onChange);
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final status = _notifier.status;
    if (status == UploadStatus.idle) return const SizedBox.shrink();

    final isFailed = status == UploadStatus.failed;
    final isComplete = status == UploadStatus.success;
    final progress = _notifier.progress;
    final pct = (progress * 100).toInt();

    final Color stateColor = isFailed ? AppColors.hopperPink : AppColors.primary;
    final Color stateBg = isFailed
        ? AppColors.hopperPink.withValues(alpha: 0.08)
        : (isComplete
            ? AppColors.primary.withValues(alpha: 0.08)
            : const Color(0xFFF8FAFC));

    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          // Bound the width to the screen so the inner Row/button never
          // receive infinite-width constraints from a shrink-wrapping parent.
          width: MediaQuery.sizeOf(context).width,
          child: Material(
          color: Colors.transparent,
          child: Container(
            margin: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
            padding: EdgeInsets.all(14.w),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: isFailed
                    ? AppColors.hopperPink.withValues(alpha: 0.3)
                    : (isComplete
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : const Color(0xFFE2E8F0)),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  spreadRadius: 1,
                  blurRadius: 10,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    AnimatedBuilder(
                      animation: _pulse,
                      builder: (context, child) => Transform.translate(
                        offset: Offset(
                          0,
                          (isComplete || isFailed) ? 0.0 : -3.0 * _pulse.value,
                        ),
                        child: child,
                      ),
                      child: Container(
                        padding: EdgeInsets.all(8.w),
                        decoration:
                            BoxDecoration(color: stateBg, shape: BoxShape.circle),
                        child: Icon(
                          isFailed
                              ? Icons.error_outline_rounded
                              : (isComplete
                                  ? Icons.check_circle_rounded
                                  : Icons.cloud_upload_outlined),
                          color: stateColor,
                          size: 22.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isFailed
                                ? 'Upload Failed'
                                : (isComplete
                                    ? 'Upload Complete'
                                    : 'Uploading content...'),
                            style: TextStyle(
                              fontSize: 13.5.sp,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'AirbnbCereal',
                              color: isFailed
                                  ? AppColors.hopperPink
                                  : Colors.black,
                            ),
                          ),
                          SizedBox(height: 2.h),
                          Text(
                            _notifier.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 11.sp,
                              color: Colors.grey.shade600,
                              fontFamily: 'AirbnbCereal',
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: _notifier.reset,
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      icon: Icon(Icons.close,
                          size: 18.sp, color: Colors.grey.shade400),
                    ),
                  ],
                ),
                SizedBox(height: 12.h),
                if (isFailed)
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Network error. Please try again.',
                          style: TextStyle(
                            fontSize: 11.sp,
                            color: Colors.grey.shade500,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                      SizedBox(width: 8.w),
                      ElevatedButton.icon(
                        onPressed: _retrying
                            ? null
                            : () async {
                                setState(() => _retrying = true);
                                await _notifier.retry();
                                if (mounted) setState(() => _retrying = false);
                              },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.hopperPink,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          // Prevents the tap-target padding from forcing an
                          // infinite width when laid out inside the Row.
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          padding: EdgeInsets.symmetric(
                              horizontal: 12.w, vertical: 6.h),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8.r),
                          ),
                        ),
                        icon: _retrying
                            ? SizedBox(
                                width: 12.w,
                                height: 12.w,
                                child: const CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Icon(Icons.refresh_rounded, size: 14.sp),
                        label: Text(
                          'Retry',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ],
                  )
                else
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10.r),
                        child: SizedBox(
                          height: 20.h,
                          width: double.infinity,
                          child: LinearProgressIndicator(
                            value: isComplete ? 1.0 : progress,
                            backgroundColor: const Color(0xFFF1F5F9),
                            color: stateColor,
                          ),
                        ),
                      ),
                      Text(
                        '$pct%',
                        style: TextStyle(
                          fontSize: 10.sp,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'AirbnbCereal',
                          color: progress > 0.55 ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
        ),
      ),
    );
  }
}
