import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

class FirebaseLogger {
  FirebaseLogger._();

  static final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  static final FirebaseCrashlytics _crashlytics = FirebaseCrashlytics.instance;

  static Future<void> logEvent({
    required String name,
    Map<String, Object>? parameters,
  }) async {
    if (kDebugMode) {
      debugPrint("FirebaseLogger [DebugMode]: Logged event '$name' with parameters: $parameters");
      return;
    }
    try {
      await _analytics.logEvent(name: name, parameters: parameters);
      debugPrint(
        "FirebaseLogger: Logged event '$name' with parameters: $parameters",
      );
    } catch (e, stack) {
      debugPrint("FirebaseLogger: Failed to log event '$name': $e");
      recordError(e, stack, reason: "Failed to log event '$name'");
    }
  }

  static Future<void> setUserId(String userId) async {
    if (kDebugMode) {
      debugPrint("FirebaseLogger [DebugMode]: User ID set to '$userId'");
      return;
    }
    try {
      await _analytics.setUserId(id: userId);
      await _crashlytics.setUserIdentifier(userId);
      debugPrint("FirebaseLogger: User ID set to '$userId'");
    } catch (e, stack) {
      debugPrint("FirebaseLogger: Failed to set user ID: $e");
      recordError(e, stack, reason: "Failed to set user ID");
    }
  }

  /// Set a user property in Analytics
  static Future<void> setUserProperty({
    required String name,
    required String value,
  }) async {
    if (kDebugMode) {
      debugPrint("FirebaseLogger [DebugMode]: User property '$name' set to '$value'");
      return;
    }
    try {
      await _analytics.setUserProperty(name: name, value: value);
      debugPrint("FirebaseLogger: User property '$name' set to '$value'");
    } catch (e, stack) {
      debugPrint("FirebaseLogger: Failed to set user property: $e");
      recordError(e, stack, reason: "Failed to set user property '$name'");
    }
  }

  static Future<void> recordError(
    dynamic error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kDebugMode) {
      debugPrint(
        "FirebaseLogger [DebugMode]: Recorded error: $error (reason: $reason, fatal: $fatal)",
      );
      return;
    }
    try {
      await _crashlytics.recordError(
        error,
        stack,
        reason: reason,
        fatal: fatal,
      );
      debugPrint(
        "FirebaseLogger: Recorded error: $error (reason: $reason, fatal: $fatal)",
      );
    } catch (e) {
      debugPrint("FirebaseLogger: Failed to record error to Crashlytics: $e");
    }
  }

  static Future<void> logMessage(String message) async {
    if (kDebugMode) {
      debugPrint("FirebaseLogger [DebugMode]: Crashlytics log: $message");
      return;
    }
    try {
      await _crashlytics.log(message);
      debugPrint("FirebaseLogger: Crashlytics log: $message");
    } catch (e) {
      debugPrint("FirebaseLogger: Failed to log message to Crashlytics: $e");
    }
  }
}
