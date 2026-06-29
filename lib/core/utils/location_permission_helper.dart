import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import '../constants/app_colors.dart';
import '../constants/app_text_styles.dart';

class LocationPermissionHelper {
  LocationPermissionHelper._();

  /// Checks location permission status, showing the disclosure popup if needed.
  static Future<void> checkAndRequestLocationPermission(
    BuildContext context,
  ) async {
    final permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      if (context.mounted) {
        final accepted = await showDisclosureDialog(context);
        if (accepted) {
          await Geolocator.requestPermission();
        }
      }
    }
  }

  static Future<bool> showDisclosureDialog(BuildContext context) async {
    final size = MediaQuery.of(context).size;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return PopScope(
          canPop: false,
          child: AlertDialog(
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
                          "Location Permission",
                          style: AppTextStyles.h3.copyWith(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        IconButton(
                          onPressed: () => Navigator.pop(ctx, false),
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
                              'assets/rabbits/logout_rabbit.png',
                              height: size.width * 0.30,
                              width: size.width * 0.35,
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),
                        Expanded(
                          child: Text(
                            'Shieldhop collects location data to enable live shift tracking, mileage calculation, and teammate SOS safety coordination even when the app is closed or not in use.',
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: Colors.black,
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
                    child: Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: size.width * 0.12,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.black,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    size.width * 0.03,
                                  ),
                                ),
                              ),
                              onPressed: () {
                                Navigator.pop(ctx, false);
                              },
                              child: Text(
                                'Deny',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.038,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'AirbnbCereal',
                                ),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(width: size.width * 0.04),
                        Expanded(
                          child: SizedBox(
                            height: size.width * 0.12,
                            child: ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                    size.width * 0.03,
                                  ),
                                ),
                              ),
                              onPressed: () => Navigator.pop(ctx, true),
                              child: Text(
                                'Accept',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: size.width * 0.038,
                                  fontWeight: FontWeight.w600,
                                  fontFamily: 'AirbnbCereal',
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
    return accepted ?? false;
  }
}
