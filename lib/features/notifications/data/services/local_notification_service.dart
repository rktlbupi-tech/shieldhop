import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import '../../../../main.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint(
    '[BackgroundFCM] Handling background message: ${message.messageId}',
  );
  debugPrint(
    '[BackgroundFCM] notification_type: ${message.data["notification_type"]}',
  );
  debugPrint('[BackgroundFCM] data: ${message.data}');

  if (message.data.isNotEmpty) {
    final localNotifService = LocalNotificationService.instance;
    await localNotifService.flutterLocalNotificationsPlugin.cancelAll();
    await localNotifService.showFlutterNotificationWithSound(message);
  }
}

@pragma('vm:entry-point')
void notificationTapBackground(
  NotificationResponse notificationResponse,
) async {
  DartPluginRegistrant.ensureInitialized();
  debugPrint(
    '[BackgroundNotif] tapped: ${notificationResponse.actionId} payload: ${notificationResponse.payload}',
  );
}

class LocalNotificationService {
  LocalNotificationService._();
  static final LocalNotificationService instance = LocalNotificationService._();

  final FlutterLocalNotificationsPlugin flutterLocalNotificationsPlugin =
      FlutterLocalNotificationsPlugin();

  Future<void> setup() async {
    // Request permission
    if (Platform.isAndroid) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();
    } else if (Platform.isIOS) {
      await flutterLocalNotificationsPlugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('ic_noti_logo');

    const DarwinInitializationSettings initializationSettingsDarwin =
        DarwinInitializationSettings(
          requestAlertPermission: false,
          requestBadgePermission: false,
          requestSoundPermission: false,
        );

    const InitializationSettings initializationSettings =
        InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsDarwin,
        );

    await flutterLocalNotificationsPlugin.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        debugPrint(
          '[ForegroundNotif] Notification tapped in foreground/background: ${response.payload}',
        );
        _handleNotificationTapPayload(response.payload);
      },
      onDidReceiveBackgroundNotificationResponse: notificationTapBackground,
    );

    // Setup foreground FCM presentation options
    await FirebaseMessaging.instance
        .setForegroundNotificationPresentationOptions(
          alert: true,
          badge: true,
          sound: true,
        );

    // Listen to foreground FCM messages
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      debugPrint('[ForegroundFCM] Message received: ${message.messageId}');
      showFlutterNotificationWithSound(message);
    });

    // Listen to notifications that opened the app
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint(
        '[ForegroundFCM] App opened via notification: ${message.messageId}',
      );
      _handleNotificationTapPayload(jsonEncode(message.data));
    });
  }

  void _handleNotificationTapPayload(String? payload) {
    if (payload == null || payload.isEmpty) return;
    try {
      final data = jsonDecode(payload);
      final context = navigatorKey.currentContext;
      if (context == null) {
        debugPrint(
          '[NotificationNavigation] Navigator context is null, skipping navigation.',
        );
        return;
      }

      final type = data['notification_type']?.toString();
      debugPrint('[NotificationNavigation] Processing type: $type');

      if (type == 'media_house_tasks' ||
          type == 'employee-task' ||
          data['employee-task'] != null) {
        context.go('/dashboard?tab=1'); // Tasks tab
      } else if (type == 'new_incident_created' ||
          data['message_type']?.toString() == 'new_incident_created') {
        context.go('/dashboard?tab=3'); // Team map tab
      } else {
        context.go('/dashboard?tab=2'); // Default to Home
      }
    } catch (e) {
      debugPrint('[NotificationNavigation] Error parsing payload: $e');
    }
  }

  Future<void> showFlutterNotificationWithSound(RemoteMessage message) async {
    StyleInformation? styleInformation;
    try {
      final imageUrl = message.data['image']?.toString();
      if (imageUrl != null && imageUrl.isNotEmpty) {
        final response = await http.get(Uri.parse(imageUrl));
        styleInformation = BigPictureStyleInformation(
          ByteArrayAndroidBitmap.fromBase64String(
            base64Encode(response.bodyBytes),
          ),
        );
      }
    } catch (e) {
      debugPrint('[LocalNotif] Failed to fetch notification image: $e');
    }

    styleInformation ??= BigTextStyleInformation(
      message.notification?.body ?? '',
    );

    final notification = message.notification;
    if (notification != null) {
      await flutterLocalNotificationsPlugin.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            'presshop_custom_sound',
            'presshop_custom_sound',
            channelDescription: 'Android_Channel_custom_sound',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.black,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.message,
            styleInformation: styleInformation,
          ),
          iOS: const DarwinNotificationDetails(
            presentSound: true,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        payload: jsonEncode(message.data),
      );
    }
  }

  Future<void> showTestNotification() async {
      await flutterLocalNotificationsPlugin.show(
        999,
        'Test Notification',
        'Your notifications are working successfully!',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'presshop_custom_sound',
            'presshop_custom_sound',
            channelDescription: 'Android_Channel_custom_sound',
            importance: Importance.high,
            priority: Priority.high,
            color: Colors.black,
            playSound: true,
            enableVibration: true,
            category: AndroidNotificationCategory.message,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentBadge: true,
            presentAlert: true,
          ),
        ),
        payload: jsonEncode({'notification_type': 'media_house_tasks'}),
      );
  }
}
