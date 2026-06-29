import 'package:flutter/material.dart';
import 'package:location/location.dart' show LocationData;
import 'package:geolocator/geolocator.dart';

/// Resolves the device's current location for the camera/preview flow.
///
/// Uses **Geolocator** (the same reliable mechanism the Team map uses) instead
/// of the `location` plugin, which was returning null on iOS. The result is
/// wrapped back into a [LocationData] so callers don't need to change.
class CameraLocationService {
  Future<LocationData?> getCurrentLocation(
    BuildContext context, {
    bool shouldShowSettingPopup = true,
  }) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return null;

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        // final accepted = await LocationPermissionHelper.showDisclosureDialog(context);
        // if (accepted) {
          permission = await Geolocator.requestPermission();
        // }
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      Position? pos;
      try {
        pos = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.high,
          ),
        ).timeout(const Duration(seconds: 8));
      } catch (_) {
        // Live fix timed out — fall back to the last known position.
        pos = await Geolocator.getLastKnownPosition();
      }
      if (pos == null) return null;

      return LocationData.fromMap({
        'latitude': pos.latitude,
        'longitude': pos.longitude,
        'accuracy': pos.accuracy,
        'altitude': pos.altitude,
        'speed': pos.speed,
        'heading': pos.heading,
      });
    } catch (_) {
      return null;
    }
  }
}
