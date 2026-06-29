import '../../../../core/network/api_client.dart';
import '../../../../core/network/api_endpoints.dart';
import '../models/notification_model.dart';

class NotificationsRemoteDatasource {
  final ApiClient _client;
  NotificationsRemoteDatasource(this._client);

  Future<NotificationListResponse> fetchNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    final res = await _client.get(
      ApiEndpoints.notifications,
      queryParameters: {
        'page': page,
        'limit': limit,
        'sortBy': 'createdAt',
        'sortOrder': 'desc',
      },
    );
    return NotificationListResponse.fromJson(res.data as Map<String, dynamic>);
  }

  Future<int> fetchUnreadCount() async {
    final res = await _client.get('${ApiEndpoints.notifications}/unread-count');
    final data = res.data;
    return data['unreadCount'] ?? data['unread_count'] ?? data['data']?['unreadCount'] ?? 0;
  }

  Future<bool> markAllAsRead() async {
    final res = await _client.patch('${ApiEndpoints.notifications}/read-all');
    return res.statusCode == 200 || res.statusCode == 204;
  }
}
