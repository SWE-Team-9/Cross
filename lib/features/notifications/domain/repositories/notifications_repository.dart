import '../entities/notification_entity.dart';
import '../entities/notification_preferences_entity.dart';
import '../entities/notifications_result.dart';

abstract class NotificationsRepository {
  Future<NotificationsResult<List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
    String? type,
    bool? isRead,
  });

  Future<NotificationsResult<int>> getUnreadCount();

  Future<NotificationsResult<void>> markAsRead(String notificationId);

  Future<NotificationsResult<void>> markAllAsRead();

  Future<NotificationsResult<void>> deleteNotification(String notificationId);

  Future<NotificationsResult<NotificationPreferencesEntity>> getPreferences();

  Future<NotificationsResult<void>> updatePreferences(
    NotificationPreferencesEntity preferences,
  );

  Future<NotificationsResult<void>> registerDevice({
    required String deviceToken,
    required String platform,
  });

  Future<NotificationsResult<void>> removeDevice(String deviceId);

  Stream<NotificationEntity> get notificationStream;
}
