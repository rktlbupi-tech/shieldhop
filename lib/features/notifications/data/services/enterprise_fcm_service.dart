import 'dart:io';
import 'dart:math';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../config/di/injection.dart';
import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';

class EnterpriseFcmService {
  static const String _deviceIdKey = 'enterprise_device_id';

  static Future<String> getOrCreateDeviceId() async {
    final prefs = getIt<SharedPreferences>();
    final stored = prefs.getString(_deviceIdKey);
    if (stored != null && stored.isNotEmpty) return stored;

    final platform = Platform.isAndroid ? 'android' : 'ios';
    final uuid = _generateUuid();
    final deviceId = '$platform-$uuid';
    await prefs.setString(_deviceIdKey, deviceId);
    return deviceId;
  }

  static Future<void> registerToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken == null || fcmToken.isEmpty) return;

      final deviceId = await getOrCreateDeviceId();
      final type = Platform.isAndroid ? 'android' : 'ios';

      final apiClient = getIt<ApiClient>();
      await apiClient.post(
        ApiEndpoints.fcmToken,
        data: {
          'device_id': deviceId,
          'device_token': fcmToken,
          'type': type,
        },
      );
      debugPrint('[EnterpriseFCM] Token registered: $deviceId');
    } catch (e) {
      debugPrint('[EnterpriseFCM] Token registration failed: $e');
    }
  }

  static Future<void> removeToken() async {
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      final prefs = getIt<SharedPreferences>();
      final deviceId = prefs.getString(_deviceIdKey) ?? '';
      if (fcmToken == null || fcmToken.isEmpty || deviceId.isEmpty) return;

      final apiClient = getIt<ApiClient>();
      await apiClient.delete(
        ApiEndpoints.fcmToken,
        data: {
          'device_id': deviceId,
          'device_token': fcmToken,
        },
      );
      debugPrint('[EnterpriseFCM] Token removed: $deviceId');
    } catch (e) {
      debugPrint('[EnterpriseFCM] Token removal failed: $e');
    }
  }

  /// Call once at app startup. Re-registers token on refresh only when logged
  /// in (meaning auth_token is present).
  static void setupTokenRefreshListener() {
    FirebaseMessaging.instance.onTokenRefresh.listen((newToken) async {
      final prefs = getIt<SharedPreferences>();
      final token = prefs.getString('auth_token') ?? '';
      if (token.isNotEmpty) {
        await registerToken();
      }
    });
  }

  static String _generateUuid() {
    final rng = Random.secure();
    final bytes = List<int>.generate(16, (_) => rng.nextInt(256));
    bytes[6] = (bytes[6] & 0x0f) | 0x40;
    bytes[8] = (bytes[8] & 0x3f) | 0x80;
    final hex = bytes
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();
    return '${hex.substring(0, 8)}-${hex.substring(8, 12)}-'
        '${hex.substring(12, 16)}-${hex.substring(16, 20)}-'
        '${hex.substring(20, 32)}';
  }
}
