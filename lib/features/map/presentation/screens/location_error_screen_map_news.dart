import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../dashboard/presentation/screens/dashboard_screen.dart';

class LocationErrorScreenMapNews extends StatefulWidget {
  final VoidCallback onTapSettings;
  const LocationErrorScreenMapNews({super.key, required this.onTapSettings});

  @override
  State<LocationErrorScreenMapNews> createState() =>
      _LocationErrorScreenMapNewsState();
}

class _LocationErrorScreenMapNewsState
    extends State<LocationErrorScreenMapNews> {
  bool _isFetchingLocation = false;

  Future<void> _enableLocation() async {
    setState(() => _isFetchingLocation = true);
    try {
      // 1. Check & request permission.
      var status = await Permission.location.status;
      if (!status.isGranted) {
        // if (mounted) {
        //   final accepted = await LocationPermissionHelper.showDisclosureDialog(context);
        //   if (accepted) {
        status = await Permission.location.request();
        //   }
        // }
      }

      // 2. Still blocked → open App Settings. The map's app-lifecycle handler
      //    re-checks the permission when the user comes back.
      if (status.isDenied ||
          status.isPermanentlyDenied ||
          status.isRestricted) {
        await openAppSettings();
        return;
      }

      // 3. Granted → make sure location services are on.
      if (!await Geolocator.isLocationServiceEnabled()) {
        await Geolocator.openLocationSettings();
        return;
      }

      // 4. Hand control back to the map (re-runs _initLocation).
      widget.onTapSettings();
    } finally {
      if (mounted) setState(() => _isFetchingLocation = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Center(
          child: Padding(
            padding: EdgeInsets.all(16.w),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Spacer(),
                // Illustration card
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: 16.w,
                    vertical: 16.w,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F2F4),
                    borderRadius: BorderRadius.circular(16.r),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(24.r),
                        child: Image.asset(
                          'assets/rabbits/logout_rabbit.png',
                          height: 110.w,
                          width: 110.w,
                          fit: BoxFit.cover,
                        ),
                      ),
                      SizedBox(width: 18.w),
                      Flexible(
                        child: Text(
                          'Help us help you stay informed',
                          style: TextStyle(
                            fontSize: 15.sp,
                            color: Colors.black,
                            fontWeight: FontWeight.w600,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 28.h),
                Text(
                  'Note: The press needs to know where a photo or video was '
                  'taken, and without your location, we can’t submit and '
                  'help sell your content. Pop it on and you’re good to go!',
                  style: TextStyle(
                    fontSize: 13.sp,
                    color: Colors.black,
                    height: 1.45,
                    fontWeight: FontWeight.w400,
                    fontFamily: 'AirbnbCereal',
                  ),
                ),
                SizedBox(height: 28.h),
                Row(
                  children: [
                    // Back
                    SizedBox(
                      height: 48.h,
                      width: 150.w,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: () => context
                            .findAncestorStateOfType<DashboardScreenState>()
                            ?.changeTab(2),
                        child: Text(
                          'Back',
                          style: TextStyle(
                            fontSize: 14.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ),
                    const Spacer(),
                    // Enable Location
                    SizedBox(
                      height: 48.h,
                      width: 150.w,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _isFetchingLocation
                              ? Colors.grey
                              : AppColors.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12.r),
                          ),
                        ),
                        onPressed: _isFetchingLocation ? null : _enableLocation,
                        child: Text(
                          'Enable Location',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 13.sp,
                            fontWeight: FontWeight.w700,
                            fontFamily: 'AirbnbCereal',
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                if (_isFetchingLocation)
                  Text(
                    'Fetching Location. Please wait while we are trying to '
                    'fetch your location. Be with us.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11.sp,
                      color: Colors.grey,
                      fontWeight: FontWeight.w400,
                      fontFamily: 'AirbnbCereal',
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
