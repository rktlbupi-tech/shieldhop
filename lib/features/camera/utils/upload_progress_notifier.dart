import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:permission_handler/permission_handler.dart';

enum UploadStatus { idle, uploading, success, failed }

class UploadProgressNotifier extends ChangeNotifier {
  UploadProgressNotifier._();
  static final UploadProgressNotifier instance = UploadProgressNotifier._();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  bool _notificationsInitialized = false;
  int _lastNotificationPct = -1;

  UploadStatus _status = UploadStatus.idle;
  double _progress = 0.0;
  String _title = '';
  String _taskId = '';
  String _progressTitle = 'Uploading Content';
  Future<bool> Function()? _onRetry;

  UploadStatus get status => _status;
  double get progress => _progress;
  String get title => _title;
  bool get isUploading => _status == UploadStatus.uploading;

  Future<void> init() async {
    await _ensureNotificationsInitialized();
  }

  Future<void> _ensureNotificationsInitialized() async {
    if (_notificationsInitialized) return;
    try {
      // Request permission using permission_handler
      final status = await Permission.notification.status;
      if (status.isDenied) {
        await Permission.notification.request();
      }

      const androidInit = AndroidInitializationSettings('ic_noti_logo');
      const iosInit = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings = InitializationSettings(
        android: androidInit,
        iOS: iosInit,
      );
      await _localNotifications.initialize(initSettings);
      _notificationsInitialized = true;
    } catch (e) {
      debugPrint('Error initializing local notifications: $e');
    }
  }

  void startUpload({
    required String taskId,
    required String title,
    Future<bool> Function()? onRetry,
    String progressTitle = 'Uploading Content',
  }) {
    _taskId = taskId;
    _title = title;
    _progressTitle = progressTitle;
    _status = UploadStatus.uploading;
    _progress = 0.0;
    _onRetry = onRetry;
    _lastNotificationPct = -1;
    notifyListeners();

    _ensureNotificationsInitialized().then((_) {
      _showProgressNotification(0);
    });
  }

  void updateProgress(double fraction) {
    _progress = fraction.clamp(0.0, 1.0);
    notifyListeners();

    final pct = (_progress * 100).toInt();
    if (pct != _lastNotificationPct) {
      _lastNotificationPct = pct;
      _ensureNotificationsInitialized().then((_) {
        _showProgressNotification(pct);
      });
    }
  }

  void completeUpload({String? title, String? body}) {
    _status = UploadStatus.success;
    _progress = 1.0;
    notifyListeners();

    _ensureNotificationsInitialized().then((_) {
      _localNotifications.cancel(1);
      _localNotifications.show(
        1,
        title ?? 'Upload Complete',
        body ?? 'Your content has been submitted successfully.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'upload_channel',
            'Video Upload',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentBanner: true,
            presentList: true,
            presentBadge: true,
          ),
        ),
      );
    });
  }

  void failUpload() {
    _status = UploadStatus.failed;
    notifyListeners();

    _ensureNotificationsInitialized().then((_) {
      _localNotifications.cancel(1);
      _localNotifications.show(
        1,
        'Upload Failed',
        'Could not submit content.',
        const NotificationDetails(
          android: AndroidNotificationDetails(
            'upload_channel',
            'Video Upload',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: DarwinNotificationDetails(
            presentSound: true,
            presentBanner: true,
            presentList: true,
            presentBadge: true,
          ),
        ),
      );
    });
  }

  void _showProgressNotification(int progressPct) {
    _localNotifications.show(
      1,
      _progressTitle,
      _title.isNotEmpty ? '$_title • $progressPct%' : 'Progress: $progressPct%',
      NotificationDetails(
        android: AndroidNotificationDetails(
          'upload_channel',
          'Video Upload',
          importance: Importance.max,
          priority: Priority.high,
          showProgress: true,
          maxProgress: 100,
          progress: progressPct,
          onlyAlertOnce: true,
          ongoing: true,
        ),
        iOS: DarwinNotificationDetails(
          presentSound: false,
          presentBanner: progressPct == 0,
          presentList: true,
          presentBadge: false,
        ),
      ),
    );
  }

  Future<void> retry() async {
    if (_onRetry != null) {
      startUpload(taskId: _taskId, title: _title, onRetry: _onRetry);
      await _onRetry!();
    }
  }

  void reset() {
    _status = UploadStatus.idle;
    _progress = 0.0;
    _title = '';
    _taskId = '';
    _onRetry = null;
    _lastNotificationPct = -1;
    notifyListeners();
  }
}
