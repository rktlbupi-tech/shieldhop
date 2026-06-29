import '../../../../core/errors/failures.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_datasource.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDatasource _ds;

  NotificationsRepositoryImpl(this._ds);

  @override
  Future<(List<NotificationEntity>, int, Failure?)> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _ds.fetchNotifications(page: page, limit: limit);
      final List<NotificationEntity> entities = response.data.map((m) => m.toEntity()).toList();
      return (entities, response.unreadCount, null);
    } on Failure catch (f) {
      return (<NotificationEntity>[], 0, f);
    } catch (e) {
      return (<NotificationEntity>[], 0, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(int, Failure?)> fetchUnreadCount() async {
    try {
      final count = await _ds.fetchUnreadCount();
      return (count, null);
    } on Failure catch (f) {
      return (0, f);
    } catch (e) {
      return (0, UnknownFailure(e.toString()));
    }
  }

  @override
  Future<(bool, Failure?)> markAllAsRead() async {
    try {
      final success = await _ds.markAllAsRead();
      return (success, null);
    } on Failure catch (f) {
      return (false, f);
    } catch (e) {
      return (false, UnknownFailure(e.toString()));
    }
  }
}
