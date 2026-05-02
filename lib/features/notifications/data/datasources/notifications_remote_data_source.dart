import '../../../../core/network/dio_client.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../models/notification_model.dart';
import '../models/notification_preferences_model.dart';

abstract class NotificationsRemoteDataSource {
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  });

  Future<int> getUnreadCount();
  Future<void> markAsRead(String notificationId);
  Future<void> markAllAsRead();
  Future<void> deleteNotification(String notificationId);
  Future<NotificationPreferencesModel> getPreferences();
  Future<void> updatePreferences(NotificationPreferencesModel preferences);
  Future<void> registerDevice({
    required String deviceToken,
    required String platform,
  });
  Future<void> removeDevice(String deviceId);
  Stream<NotificationModel> get notificationStream;
}

class NotificationsRemoteDataSourceImpl
    implements NotificationsRemoteDataSource {
  NotificationsRemoteDataSourceImpl({
    required DioClient client,
    Stream<NotificationModel>? notificationStream,
  })  : _client = client,
        _notificationStream = notificationStream ?? const Stream.empty();

  final DioClient _client;
  final Stream<NotificationModel> _notificationStream;

  static const String _base = '/api/v1/notifications';

  @override
  Future<List<NotificationModel>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  }) async {
    final query = <String, dynamic>{'page': page, 'limit': limit};
    if (type != null && type.isNotEmpty) {
      query['type'] = type;
    }
    if (isRead != null) {
      query['isRead'] = isRead;
    }

    final response = await _client.get(
      _base,
      queryParameters: query,
    );

    final payload = _extractPayload(response.data);
    final list = _extractList(payload);

    return list
        .whereType<Map>()
        .map((item) =>
            NotificationModel.fromJson(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<int> getUnreadCount() async {
    final response = await _client.get('$_base/unread-count');
    final payload = _extractPayload(response.data);

    if (payload is Map<String, dynamic>) {
      final raw =
          payload['count'] ?? payload['unreadCount'] ?? payload['unread'];
      if (raw is num) return raw.toInt();
      return int.tryParse(raw?.toString() ?? '') ?? 0;
    }

    if (payload is num) return payload.toInt();
    return int.tryParse(payload.toString()) ?? 0;
  }

  @override
  Future<void> markAsRead(String notificationId) async {
    await _client.patch('$_base/$notificationId/read');
  }

  @override
  Future<void> markAllAsRead() async {
    await _client.patch('$_base/read-all');
  }

  @override
  Future<void> deleteNotification(String notificationId) async {
    await _client.delete('$_base/$notificationId');
  }

  @override
  Future<NotificationPreferencesModel> getPreferences() async {
    try {
      final response = await _client.get('$_base/preferences');
      final payload = _extractPayload(response.data);

      if (payload is Map<String, dynamic>) {
        return NotificationPreferencesModel.fromJson(payload);
      }
      // Fallback to defaults if parsing fails
      return NotificationPreferencesModel.fromEntity(
        NotificationPreferencesEntity.defaults(),
      );
    } catch (e) {
      // Return defaults on any error
      return NotificationPreferencesModel.fromEntity(
        NotificationPreferencesEntity.defaults(),
      );
    }
  }

  @override
  Future<void> updatePreferences(
      NotificationPreferencesModel preferences) async {
    await _client.put('$_base/preferences', data: preferences.toJson());
  }

  @override
  Future<void> registerDevice({
    required String deviceToken,
    required String platform,
  }) async {
    await _client.post(
      '$_base/push/register',
      data: {
        'deviceToken': deviceToken,
        'platform': platform,
      },
    );
  }

  @override
  Future<void> removeDevice(String deviceId) async {
    await _client.delete('$_base/push/$deviceId');
  }

  @override
  Stream<NotificationModel> get notificationStream => _notificationStream;

  dynamic _extractPayload(dynamic source) {
    if (source is Map<String, dynamic>) {
      return source['data'] ?? source;
    }
    return source;
  }

  List<dynamic> _extractList(dynamic payload) {
    if (payload is List<dynamic>) return payload;

    if (payload is Map<String, dynamic>) {
      final items =
          payload['items'] ?? payload['notifications'] ?? payload['results'];
      if (items is List<dynamic>) return items;
    }

    return const <dynamic>[];
  }
}
