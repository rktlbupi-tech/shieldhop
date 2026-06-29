import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:presshop_enterprise/core/network/api_client.dart';
import 'package:presshop_enterprise/config/di/injection.dart';

class ForceUpdateRepository {
  static const String endpoint = "auth/getLatestVersion";

  static DateTime? _lastCheckTime;
  static String? _cachedCurrentVersion;
  static bool? _isForceUpdateRequired;
  static Future<bool>? _inProgressCheck;

  static Future<bool> checkForceUpdate({bool forceRefresh = false}) async {
    if (!forceRefresh && _isForceUpdateRequired != null) {
      debugPrint(
        "Returning cached force update decision: $_isForceUpdateRequired",
      );
      return _isForceUpdateRequired!;
    }
    if (_inProgressCheck != null) {
      debugPrint("Returning in-progress check Future");
      return _inProgressCheck!;
    }

    _inProgressCheck = _performCheck(forceRefresh: forceRefresh);
    try {
      final res = await _inProgressCheck!;
      return res;
    } finally {
      _inProgressCheck = null;
    }
  }

  static Future<bool> _performCheck({bool forceRefresh = false}) async {
    final now = DateTime.now();
    if (!forceRefresh &&
        _lastCheckTime != null &&
        now.difference(_lastCheckTime!) < const Duration(minutes: 5)) {
      debugPrint("Skipping force update check (cooldown active)");
      return _isForceUpdateRequired ?? false;
    }
    _lastCheckTime = now;
    // dsfsdsd
    try {
      final apiClient = getIt<ApiClient>();
      final response = await apiClient.get(endpoint);

      if (response.data == null || response.data["code"] != 200) {
        _isForceUpdateRequired = false;
        return false;
      }

      final data = response.data["data"];
      if (data == null) {
        _isForceUpdateRequired = false;
        return false;
      }

      // Cache package version to avoid native channel calls on repeated checks
      if (_cachedCurrentVersion == null) {
        final info = await PackageInfo.fromPlatform();
        _cachedCurrentVersion = info.version;
      }
      final currentVersion = _cachedCurrentVersion!;

      String? latestBackendVersion;
      bool backendForceFlag = false;

      if (Platform.isAndroid) {
        latestBackendVersion = data["live_Version_enterprise"]?.toString();
        backendForceFlag = data["aOSshouldForceUpdate_enterprise"] == true;
      } else if (Platform.isIOS) {
        latestBackendVersion = data["live_Version_enterprise"]?.toString();
        backendForceFlag = data["iOSshouldForceUpdate_enterprise"] == true;
      }

      debugPrint(
        "ForceUpdate check: latest=$latestBackendVersion, current=$currentVersion, forceFlag=$backendForceFlag",
      );

      if (latestBackendVersion != null) {
        bool updateAvailable = compareVersions(
          latestBackendVersion,
          currentVersion,
        );
        _isForceUpdateRequired = updateAvailable && backendForceFlag;
        return _isForceUpdateRequired!;
      }

      _isForceUpdateRequired = false;
      return false;
    } catch (e) {
      debugPrint("Error checking force update: $e");
      return _isForceUpdateRequired ?? false;
    }
  }

  /// Compare two semantic version strings. Returns true if latest is greater than current.
  static bool compareVersions(String latest, String current) {
    final latestParts = latest
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();
    final currentParts = current
        .split('.')
        .map((e) => int.tryParse(e) ?? 0)
        .toList();

    for (int i = 0; i < latestParts.length; i++) {
      if (i >= currentParts.length) return true;
      if (latestParts[i] > currentParts[i]) return true;
      if (latestParts[i] < currentParts[i]) return false;
    }
    return false;
  }
}
