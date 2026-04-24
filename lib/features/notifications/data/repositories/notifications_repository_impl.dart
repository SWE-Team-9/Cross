import '../../../../core/errors/failure.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/entities/notifications_result.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../datasources/notifications_remote_data_source.dart';
import '../models/notification_preferences_model.dart';

class NotificationsRepositoryImpl implements NotificationsRepository {
  final NotificationsRemoteDataSource _remote;

  const NotificationsRepositoryImpl(this._remote);

  @override
  Future<NotificationsResult<List<NotificationEntity>>> getNotifications({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final list = await _remote.getNotifications(page: page, limit: limit);
      return NotificationsResult.success(list);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to load notifications.'),
      );
    }
  }

  @override
  Future<NotificationsResult<int>> getUnreadCount() async {
    try {
      return NotificationsResult.success(await _remote.getUnreadCount());
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to load unread count.'),
      );
    }
  }

  @override
  Future<NotificationsResult<bool>> markAsRead(String notificationId) async {
    try {
      await _remote.markAsRead(notificationId);
      return const NotificationsResult.success(true);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to mark notification as read.'),
      );
    }
  }

  @override
  Future<NotificationsResult<bool>> markAllAsRead() async {
    try {
      await _remote.markAllAsRead();
      return const NotificationsResult.success(true);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to mark all notifications as read.'),
      );
    }
  }

  @override
  Future<NotificationsResult<bool>> deleteNotification(
      String notificationId) async {
    try {
      await _remote.deleteNotification(notificationId);
      return const NotificationsResult.success(true);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to delete notification.'),
      );
    }
  }

  @override
  Future<NotificationsResult<NotificationPreferencesEntity>>
      getPreferences() async {
    try {
      final model = await _remote.getPreferences();
      return NotificationsResult.success(model);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to load notification preferences.'),
      );
    }
  }

  @override
  Future<NotificationsResult<bool>> updatePreferences(
    NotificationPreferencesEntity preferences,
  ) async {
    try {
      final model = NotificationPreferencesModel.fromEntity(preferences);
      await _remote.updatePreferences(model);
      return const NotificationsResult.success(true);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to update notification preferences.'),
      );
    }
  }

  @override
  Future<NotificationsResult<bool>> registerDevice({
    required String deviceToken,
    required String platform,
  }) async {
    try {
      await _remote.registerDevice(
          deviceToken: deviceToken, platform: platform);
      return const NotificationsResult.success(true);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to register device for notifications.'),
      );
    }
  }

  @override
  Future<NotificationsResult<bool>> removeDevice(String deviceId) async {
    try {
      await _remote.removeDevice(deviceId);
      return const NotificationsResult.success(true);
    } on Failure catch (failure) {
      return NotificationsResult.failure(failure);
    } catch (e) {
      return const NotificationsResult.failure(
        ServerFailure('Failed to remove notification device.'),
      );
    }
  }

  @override
  Stream<NotificationEntity> get notificationStream {
    return _remote.notificationStream;
  }
}
