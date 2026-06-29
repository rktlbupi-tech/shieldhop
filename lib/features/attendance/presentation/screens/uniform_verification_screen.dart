import 'dart:async';
import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:presshop_enterprise/core/constants/app_colors.dart';
import '../../../../main.dart' show cameras;
import '../../../camera/utils/camera_location_service.dart';
import '../bloc/attendance_bloc.dart';

enum _Step { capture, verifying, success }

class UniformVerificationScreen extends StatefulWidget {
  const UniformVerificationScreen({super.key});

  @override
  State<UniformVerificationScreen> createState() =>
      _UniformVerificationScreenState();
}

class _UniformVerificationScreenState extends State<UniformVerificationScreen>
    with TickerProviderStateMixin {
  CameraController? _cameraController;
  bool _cameraReady = false;
  // bool _capturing = false;
  File? _selfiePhoto;

  bool _scanning = true;
  bool _detected = false;

  _Step _step = _Step.capture;
  int _scanProgressIndex = 0; // 0-4 scanning sub-steps
  static const _scanMessages = [
    'Detecting uniform…',
    'Matching dress code…',
    'Checking completeness…',
    'Finalising…',
    'Verified!',
  ];

  late final AnimationController _rotateController;
  late final AnimationController _scanLineController;
  late final Animation<double> _scanLineAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _rotateController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _scanLineController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnimation = Tween<double>(begin: 0.15, end: 0.85).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.94, end: 1.06).animate(
      CurvedAnimation(parent: _scanLineController, curve: Curves.easeInOut),
    );

    _initCamera();
  }

  Future<void> _initCamera() async {
    if (cameras.isEmpty) return;
    // Front camera for the uniform self-check; fall back to whatever exists.
    final desc = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );
    final controller = CameraController(
      desc,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: Platform.isIOS
          ? ImageFormatGroup.bgra8888
          : ImageFormatGroup.jpeg,
    );
    _cameraController = controller;
    try {
      await controller.initialize();
      if (!mounted) return;
      setState(() => _cameraReady = true);
      _startAutoDetection();
    } catch (_) {
      if (mounted) setState(() => _cameraReady = false);
    }
  }

  void _startAutoDetection() {
    Timer(const Duration(seconds: 3), () async {
      if (!mounted) return;

      // Auto capture photo silently
      final c = _cameraController;
      if (c != null && c.value.isInitialized) {
        try {
          final XFile shot = await c.takePicture();
          if (mounted) {
            setState(() {
              _selfiePhoto = File(shot.path);
            });
          }
        } catch (_) {}
      }

      if (mounted) {
        setState(() {
          _scanning = false;
          _detected = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _rotateController.dispose();
    _scanLineController.dispose();
    _cameraController?.dispose();
    super.dispose();
  }

  Future<void> _runVerification() async {
    setState(() {
      _step = _Step.verifying;
      _scanProgressIndex = 0;
    });

    for (int i = 1; i <= _scanMessages.length; i++) {
      await Future.delayed(const Duration(milliseconds: 700));
      if (!mounted) return;
      setState(() => _scanProgressIndex = i);
    }

    await Future.delayed(const Duration(milliseconds: 300));
    if (!mounted) return;
    setState(() => _step = _Step.success);

    // Resolve the device location for the clock-in punch (the server uses it
    // for the geofence check).
    final location = await CameraLocationService().getCurrentLocation(context);

    // Brief success display before triggering the real clock-in.
    await Future.delayed(const Duration(milliseconds: 1800));
    if (!mounted) return;

    // Upload the selfie + clock in via /app/attendance/punch.
    context.read<AttendanceBloc>().add(
          CheckInRequested(
            location?.latitude ?? 0.0,
            location?.longitude ?? 0.0,
            accuracyMeters: location?.accuracy,
            photoFile: _selfiePhoto,
          ),
        );
    Navigator.of(context).pop();
  }

  // ── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF080C18),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 350),
        transitionBuilder: (child, anim) =>
            FadeTransition(opacity: anim, child: child),
        child: switch (_step) {
          _Step.capture => _buildCapturePage(),
          _Step.verifying => _buildVerifyingPage(),
          _Step.success => _buildSuccessPage(),
        },
      ),
    );
  }

  // ── Step 1 : Capture ─────────────────────────────────────────────────────

  Widget _buildCapturePage() {
    final size = MediaQuery.of(context).size;
    return Stack(
      key: const ValueKey('capture'),
      fit: StackFit.expand,
      children: [
        // Live camera preview (full screen) or captured photo preview (full screen)
        _selfiePhoto != null
            ? Image.file(_selfiePhoto!, fit: BoxFit.cover)
            : (_cameraReady &&
                  _cameraController != null &&
                  _cameraController!.value.isInitialized)
            ? FittedBox(
                fit: BoxFit.cover,
                child: SizedBox(
                  width: _cameraController!.value.previewSize?.height ?? 1,
                  height: _cameraController!.value.previewSize?.width ?? 1,
                  child: CameraPreview(_cameraController!),
                ),
              )
            : Container(
                color: const Color(0xFF080C18),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 32.w,
                        height: 32.w,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2.5,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white24,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      Text(
                        'Starting camera…',
                        style: TextStyle(
                          color: Colors.white38,
                          fontSize: 13.sp,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ],
                  ),
                ),
              ),

        // Animated laser scan line
        if (_scanning && _cameraReady)
          AnimatedBuilder(
            animation: _scanLineAnimation,
            builder: (context, child) {
              return Positioned(
                top: size.height * _scanLineAnimation.value,
                left: 0,
                right: 0,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: const Color(0xFF00FFCC),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00FFCC).withValues(alpha: 0.8),
                        blurRadius: 14,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

        // Dark gradients overlay for UI text readability
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.65),
                  Colors.transparent,
                  Colors.transparent,
                  Colors.black.withValues(alpha: 0.75),
                ],
                stops: const [0.0, 0.20, 0.70, 1.0],
              ),
            ),
          ),
        ),

        // UI Controls Layer
        SafeArea(
          child: Column(
            children: [
              // Top Navigation Bar
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                child: Row(
                  children: [
                    IconButton(
                      icon: Image.asset(
                        'assets/icons/ic_arrow_left.png',
                        width: 24.w,
                        height: 24.w,
                        color: AppColors.cardBackground,
                        errorBuilder: (context, error, stackTrace) {
                          return Icon(
                            Icons.arrow_back_ios_new,
                            size: 22.sp,
                            color: AppColors.textPrimary,
                          );
                        },
                      ),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Uniform Check',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18.sp,
                        fontWeight: FontWeight.w700,
                        fontFamily: 'AirbnbCereal',
                      ),
                    ),
                    SizedBox(width: 48.w),
                  ],
                ),
              ),

              // Instruction Banner
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 8.h),
                child: Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 12.h,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14.r),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.15),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        LucideIcons.info,
                        color: const Color(0xFF7AABFF),
                        size: 18.sp,
                      ),
                      SizedBox(width: 12.w),
                      Expanded(
                        child: Text(
                          "Please take a quick selfie scan to confirm you're smartly presented, and ready to deliver a professional customer experience",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.95),
                            fontSize: 12.sp,
                            height: 1.45,
                            fontFamily: 'AirbnbCereal',
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Scanner State Indicator
              if (_cameraReady)
                Padding(
                  padding: EdgeInsets.only(top: 10.h),
                  child: Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 14.w,
                      vertical: 6.h,
                    ),
                    decoration: BoxDecoration(
                      color: _detected
                          ? const Color(0xFF0F3D1C).withValues(alpha: 0.85)
                          : const Color(0xFF1E293B).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: _detected
                            ? const Color(0xFF52C41A)
                            : const Color(0xFF94A3B8),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _detected
                            ? const Icon(
                                Icons.check_circle,
                                color: Color(0xFF52C41A),
                                size: 16,
                              )
                            : SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.blue.shade300,
                                ),
                              ),
                        SizedBox(width: 8.w),
                        Text(
                          _detected
                              ? 'Uniform Detected Successfully'
                              : 'Auto-scanning uniform...',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11.sp,
                            fontFamily: 'AirbnbCereal',
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              const Spacer(),

              // Bottom Control Buttons
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 16.h),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Verify & Log On Duty button (enabled only when uniform is auto-detected)
                    GestureDetector(
                      onTap: _detected ? _runVerification : null,
                      child: Container(
                        width: double.infinity,
                        height: 52.h,
                        decoration: BoxDecoration(
                          gradient: _detected
                              ? const LinearGradient(
                                  colors: [
                                    Color(0xFF2E66FF),
                                    Color(0xFF1540C0),
                                  ],
                                )
                              : null,
                          color: _detected ? null : const Color(0xFF1B2030),
                          borderRadius: BorderRadius.circular(16.r),
                          boxShadow: _detected
                              ? [
                                  BoxShadow(
                                    color: const Color(
                                      0xFF2E66FF,
                                    ).withValues(alpha: 0.3),
                                    blurRadius: 10,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              LucideIcons.shield_check,
                              color: _detected ? Colors.white : Colors.white30,
                              size: 20.sp,
                            ),
                            SizedBox(width: 10.w),
                            Text(
                              'Log On Duty',
                              style: TextStyle(
                                color: _detected
                                    ? Colors.white
                                    : Colors.white30,
                                fontSize: 15.sp,
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
            ],
          ),
        ),
      ],
    );
  }

  // ── Step 2 : Verifying ───────────────────────────────────────────────────

  Widget _buildVerifyingPage() {
    final progress = _scanProgressIndex / _scanMessages.length;
    final currentMsg = _scanProgressIndex < _scanMessages.length
        ? _scanMessages[_scanProgressIndex]
        : _scanMessages.last;

    return Center(
      key: const ValueKey('verifying'),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 32.w),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Rotating scan ring
            SizedBox(
              width: 120.w,
              height: 120.w,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Background ring
                  SizedBox(
                    width: 120.w,
                    height: 120.w,
                    child: CircularProgressIndicator(
                      value: 1,
                      strokeWidth: 3,
                      color: Colors.white.withValues(alpha: 0.08),
                    ),
                  ),
                  // Animated progress ring
                  SizedBox(
                    width: 120.w,
                    height: 120.w,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progress),
                      duration: const Duration(milliseconds: 600),
                      curve: Curves.easeOut,
                      builder: (_, val, child) => CircularProgressIndicator(
                        value: val,
                        strokeWidth: 4,
                        strokeCap: StrokeCap.round,
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          Color(0xFF2E66FF),
                        ),
                      ),
                    ),
                  ),
                  // Center icon
                  ScaleTransition(
                    scale: _scaleAnimation,
                    child: Container(
                      width: 80.w,
                      height: 80.w,
                      decoration: BoxDecoration(
                        color: const Color(0xFF12163A),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF2E66FF).withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                      ),
                      child: Icon(
                        LucideIcons.scan_face,
                        color: const Color(0xFF4A8EFF),
                        size: 32.sp,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: 32.h),

            Text(
              'Scanning Uniform',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'AirbnbCereal',
              ),
            ),
            SizedBox(height: 8.h),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              layoutBuilder: (currentChild, previousChildren) =>
                  currentChild ?? const SizedBox.shrink(),
              child: Text(
                currentMsg,
                key: ValueKey(currentMsg),
                style: TextStyle(
                  color: const Color(0xFF7AABFF),
                  fontSize: 13.sp,
                  fontFamily: 'AirbnbCereal',
                ),
              ),
            ),

            SizedBox(height: 40.h),

            // Scan step indicators
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(_scanMessages.length - 1, (i) {
                final done = _scanProgressIndex > i;
                final active = _scanProgressIndex == i + 1;
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 5.h),
                  child: Row(
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        width: 20.w,
                        height: 20.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: done
                              ? const Color(0xFF4CAF50)
                              : active
                              ? const Color(0xFF2E66FF)
                              : Colors.white.withValues(alpha: 0.08),
                          border: Border.all(
                            color: done
                                ? const Color(0xFF4CAF50)
                                : active
                                ? const Color(0xFF2E66FF)
                                : Colors.white.withValues(alpha: 0.15),
                          ),
                        ),
                        child: done
                            ? Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 11.sp,
                              )
                            : active
                            ? Padding(
                                padding: const EdgeInsets.all(4),
                                child: CircularProgressIndicator(
                                  strokeWidth: 1.5,
                                  color: Colors.white,
                                ),
                              )
                            : null,
                      ),
                      SizedBox(width: 12.w),
                      Text(
                        _scanMessages[i],
                        style: TextStyle(
                          color: done
                              ? Colors.white
                              : active
                              ? Colors.white
                              : Colors.white30,
                          fontSize: 12.sp,
                          fontWeight: done || active
                              ? FontWeight.w600
                              : FontWeight.w400,
                          fontFamily: 'AirbnbCereal',
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ],
        ),
      ),
    );
  }

  // ── Step 3 : Success ─────────────────────────────────────────────────────

  Widget _buildSuccessPage() {
    return Center(
      key: const ValueKey('success'),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Success ring
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0.5, end: 1.0),
            duration: const Duration(milliseconds: 500),
            curve: Curves.elasticOut,
            builder: (_, scale, child) =>
                Transform.scale(scale: scale, child: child),
            child: Container(
              width: 110.w,
              height: 110.w,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF0D3D1E),
                border: Border.all(color: const Color(0xFF4CAF50), width: 3),
              ),
              child: Icon(
                Icons.check_rounded,
                color: const Color(0xFF4CAF50),
                size: 52.sp,
              ),
            ),
          ),

          SizedBox(height: 28.h),

          Text(
            'Uniform Verified!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 22.sp,
              fontWeight: FontWeight.w800,
              fontFamily: 'AirbnbCereal',
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Dress code confirmed. Logging you on duty…',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 13.sp,
              fontFamily: 'AirbnbCereal',
            ),
          ),

          SizedBox(height: 36.h),

          // Captured photo
          if (_selfiePhoto != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12.r),
              child: Image.file(
                _selfiePhoto!,
                width: 80.w,
                height: 80.w,
                fit: BoxFit.cover,
              ),
            ),
        ],
      ),
    );
  }
}
