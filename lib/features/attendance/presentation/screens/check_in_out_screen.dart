import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:intl/intl.dart';
import '../../../../core/constants/app_colors.dart';
import '../bloc/attendance_bloc.dart';

class CheckInOutScreen extends StatefulWidget {
  final bool isCheckingIn;
  final AttendanceBloc attendanceBloc;
  const CheckInOutScreen({
    super.key,
    this.isCheckingIn = true,
    required this.attendanceBloc,
  });

  @override
  State<CheckInOutScreen> createState() => _CheckInOutScreenState();
}

class _CheckInOutScreenState extends State<CheckInOutScreen> {
  late bool _isCheckedIn;
  DateTime? _checkInTime;
  Timer? _timer;
  String _workingHours = "0h 0m";

  Position? _currentPosition;
  String _currentAddress = 'Retrieving GPS location...';
  bool _isLoadingLocation = true;

  @override
  void initState() {
    super.initState();
    _isCheckedIn = !widget.isCheckingIn;
    if (_isCheckedIn) {
      _checkInTime = DateTime(
        DateTime.now().year,
        DateTime.now().month,
        DateTime.now().day,
        9,
        15,
      );
    } else {
      _checkInTime = null;
    }
    _updateWorkingHours();
    _timer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _updateWorkingHours();
    });
    _determinePosition();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _determinePosition() async {
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        setState(() {
          _currentAddress = 'Location services are disabled.';
          _isLoadingLocation = false;
        });
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // final accepted = await LocationPermissionHelper.showDisclosureDialog(context);
        // if (accepted) {
          permission = await Geolocator.requestPermission();
        // }
        if (permission == LocationPermission.denied) {
          setState(() {
            _currentAddress = 'Location permissions are denied.';
            _isLoadingLocation = false;
          });
          return;
        }
      }
      if (permission == LocationPermission.deniedForever) {
        setState(() {
          _currentAddress = 'Location permissions are permanently denied.';
          _isLoadingLocation = false;
        });
        return;
      }
      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      setState(() {
        _currentPosition = position;
        _currentAddress = '${position.latitude.toStringAsFixed(4)}° N, ${position.longitude.toStringAsFixed(4)}° W';
        _isLoadingLocation = false;
      });

      try {
        final placemarks = await placemarkFromCoordinates(position.latitude, position.longitude);
        if (placemarks.isNotEmpty) {
          final p = placemarks.first;
          setState(() {
            _currentAddress = '${p.street ?? ""}, ${p.subLocality ?? ""}, ${p.locality ?? ""}, ${p.postalCode ?? ""}';
          });
        }
      } catch (_) {}
    } catch (e) {
      setState(() {
        _currentAddress = 'Error getting location: $e';
        _isLoadingLocation = false;
      });
    }
  }

  void _updateWorkingHours() {
    if (!_isCheckedIn || _checkInTime == null) {
      setState(() {
        _workingHours = "08h 45m";
      });
      return;
    }
    final now = DateTime.now();
    final difference = now.difference(_checkInTime!);
    if (difference.isNegative) {
      setState(() {
        _workingHours = "0h 0m";
      });
      return;
    }
    final hours = difference.inHours;
    final minutes = difference.inMinutes % 60;
    setState(() {
      _workingHours = "${hours}h ${minutes}m";
    });
  }

  void _confirmCheckStatus() {
    final lat = _currentPosition?.latitude ?? 0.0;
    final lng = _currentPosition?.longitude ?? 0.0;
    if (widget.isCheckingIn) {
      widget.attendanceBloc.add(CheckInRequested(lat, lng));
    } else {
      widget.attendanceBloc.add(CheckOutRequested(lat, lng));
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final String formattedDate = DateFormat('dd MMM yyyy').format(DateTime.now());

    return BlocConsumer<AttendanceBloc, AttendanceState>(
      bloc: widget.attendanceBloc,
      listener: (context, state) {
        if (state is AttendanceActionSuccess) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(
                    widget.isCheckingIn ? Icons.check_circle : Icons.logout_outlined,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      state.message,
                      style: const TextStyle(fontFamily: 'AirbnbCereal'),
                    ),
                  ),
                ],
              ),
              backgroundColor: widget.isCheckingIn ? AppColors.success : AppColors.error,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
          Navigator.pop(context, true);
        } else if (state is AttendanceError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(state.message),
              backgroundColor: AppColors.error,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is AttendanceLoading;

        return Scaffold(
          backgroundColor: const Color(0xFFF9FAFC),
          appBar: AppBar(
            backgroundColor: Colors.white,
            elevation: 0.5,
            centerTitle: false,
            titleSpacing: 0,
            leading: IconButton(
              icon: Image.asset('assets/icons/ic_arrow_left.png', color: Colors.black, width: 24, height: 24),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              "Check In / Out",
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontFamily: 'AirbnbCereal',
                fontSize: size.width * 0.045,
              ),
            ),
          ),
          body: SafeArea(
            child: Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: EdgeInsets.all(size.width * 0.04),
                    physics: const BouncingScrollPhysics(),
                    children: [
                      // Current Status Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEFF1F6)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.015),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Current Status",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontFamily: "AirbnbCereal",
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: _isCheckedIn
                                          ? AppColors.success.withOpacity(0.1)
                                          : const Color(0xFFFEF3C7),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          width: 6,
                                          height: 6,
                                          decoration: BoxDecoration(
                                            color: _isCheckedIn
                                                ? AppColors.success
                                                : const Color(0xFFF59E0B),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          _isCheckedIn
                                              ? "Checked In"
                                              : "Checked Out",
                                          style: TextStyle(
                                            fontSize: 11,
                                            fontWeight: FontWeight.bold,
                                            color: _isCheckedIn
                                                ? AppColors.success
                                                : const Color(0xFFF59E0B),
                                            fontFamily: "AirbnbCereal",
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    "Since",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontFamily: "AirbnbCereal",
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _isCheckedIn
                                        ? (_checkInTime != null
                                            ? DateFormat('hh:mm a')
                                                .format(_checkInTime!)
                                            : "09:15 AM")
                                        : "09:15 AM",
                                    style: TextStyle(
                                      fontSize: 28,
                                      fontWeight: FontWeight.bold,
                                      color: _isCheckedIn
                                          ? AppColors.success
                                          : Colors.grey.shade400,
                                      fontFamily: "AirbnbCereal",
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "Today, $formattedDate",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey.shade500,
                                      fontFamily: "AirbnbCereal",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            // Circular Map Stack Illustration
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                Container(
                                  width: 100,
                                  height: 100,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.05),
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                Container(
                                  width: 76,
                                  height: 76,
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.12),
                                    shape: BoxShape.circle,
                                    border:
                                        Border.all(color: Colors.white, width: 2),
                                  ),
                                  child: const Icon(
                                    LucideIcons.map_pin,
                                    color: AppColors.success,
                                    size: 36,
                                  ),
                                ),
                                if (_isCheckedIn)
                                  Positioned(
                                    bottom: 6,
                                    right: 6,
                                    child: Container(
                                      padding: const EdgeInsets.all(2),
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                      child: const Icon(
                                        Icons.check_circle,
                                        color: AppColors.success,
                                        size: 20,
                                      ),
                                    ),
                                  ),
                              ],
                            )
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Location Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEFF1F6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AppColors.success.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                LucideIcons.map_pin,
                                color: AppColors.success,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Location",
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: Colors.grey.shade500,
                                      fontFamily: "AirbnbCereal",
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    _currentAddress,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                      fontFamily: "AirbnbCereal",
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (!_isLoadingLocation)
                              InkWell(
                                onTap: () {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Location confirmed!"),
                                      behavior: SnackBarBehavior.floating,
                                    ),
                                  );
                                },
                                borderRadius: BorderRadius.circular(8),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                        color: AppColors.success
                                            .withOpacity(0.2)),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(LucideIcons.map,
                                          size: 14, color: AppColors.success),
                                      SizedBox(width: 6),
                                      Text(
                                        "View on Map",
                                        style: TextStyle(
                                          fontFamily: "AirbnbCereal",
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                          color: AppColors.success,
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

                      // Today's Timeline Card
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEFF1F6)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Today's Timeline",
                              style: TextStyle(
                                fontFamily: "AirbnbCereal",
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1E293B),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Left Timeline Nodes
                                Column(
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: _isCheckedIn
                                            ? AppColors.success.withOpacity(0.1)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.log_in,
                                        color: _isCheckedIn
                                            ? AppColors.success
                                            : Colors.grey.shade400,
                                        size: 18,
                                      ),
                                    ),
                                    Container(
                                      width: 1.5,
                                      height: 44,
                                      color: Colors.grey.shade200,
                                    ),
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: !_isCheckedIn
                                            ? const Color(0xFFFEE2E2)
                                            : Colors.grey.shade100,
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        LucideIcons.log_out,
                                        color: !_isCheckedIn
                                            ? const Color(0xFFEF4444)
                                            : Colors.grey.shade400,
                                        size: 18,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(width: 14),
                                // Right Details Column
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        "Checked In",
                                        style: TextStyle(
                                          fontFamily: "AirbnbCereal",
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: _isCheckedIn
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        _isCheckedIn
                                            ? (_checkInTime != null
                                                ? DateFormat('hh:mm a')
                                                    .format(_checkInTime!)
                                                : "09:15 AM")
                                            : "09:15 AM",
                                        style: TextStyle(
                                          fontFamily: "AirbnbCereal",
                                          fontSize: 12,
                                          color: _isCheckedIn
                                              ? AppColors.success
                                              : Colors.grey,
                                        ),
                                      ),
                                      const SizedBox(height: 38),
                                      Text(
                                        "Checked Out",
                                        style: TextStyle(
                                          fontFamily: "AirbnbCereal",
                                          fontSize: 13,
                                          fontWeight: FontWeight.bold,
                                          color: !_isCheckedIn
                                              ? Colors.black87
                                              : Colors.grey,
                                        ),
                                      ),
                                      Text(
                                        !_isCheckedIn ? "06:00 PM" : "06:00 PM",
                                        style: TextStyle(
                                          fontFamily: "AirbnbCereal",
                                          fontSize: 12,
                                          color: !_isCheckedIn
                                              ? const Color(0xFFEF4444)
                                              : Colors.grey,
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
                      const SizedBox(height: 16),

                      // Working Hours Card
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFEFF1F6)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: (_isCheckedIn && _checkInTime != null)
                                    ? const Color(0xFFEFF6FF)
                                    : Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                LucideIcons.clock,
                                color: (_isCheckedIn && _checkInTime != null)
                                    ? Colors.blue
                                    : Colors.grey,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              "Working Hours",
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                fontFamily: "AirbnbCereal",
                              ),
                            ),
                            const Spacer(),
                            Text(
                              _workingHours,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: (_isCheckedIn && _checkInTime != null)
                                    ? Colors.blue
                                    : Colors.grey,
                                fontFamily: "AirbnbCereal",
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Info Warning Banner
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F9FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0F2FE)),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(LucideIcons.info,
                                color: Colors.blue, size: 20),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    "Make sure you are at your work location",
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF0369A1),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "You can only check in when you are at the assigned work location.",
                                    style: TextStyle(
                                      fontFamily: 'AirbnbCereal',
                                      fontSize: 11,
                                      color: const Color(0xFF0369A1)
                                          .withOpacity(0.8),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Bottom Action Button
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        offset: Offset(0, -2),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: isLoading || _isLoadingLocation ? null : _confirmCheckStatus,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isCheckingIn
                            ? AppColors.success
                            : AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  LucideIcons.check,
                                  color: Colors.white,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  widget.isCheckingIn ? "Confirm Check In" : "Confirm Check Out",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontFamily: "AirbnbCereal",
                                  ),
                                ),
                              ],
                            ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
