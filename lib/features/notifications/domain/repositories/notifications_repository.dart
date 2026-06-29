import '../../../../core/errors/failures.dart';
import '../entities/notification_entity.dart';

abstract class NotificationsRepository {
  Future<(List<NotificationEntity>, int, Failure?)> fetchNotifications({int page = 1, int limit = 20});
  Future<(int, Failure?)> fetchUnreadCount();
  Future<(bool, Failure?)> markAllAsRead();
}
