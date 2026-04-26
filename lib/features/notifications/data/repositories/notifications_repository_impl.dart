import '../../../../core/errors/failure.dart';
import '../../domain/entities/notification_entity.dart';
import '../../domain/entities/notification_preferences_entity.dart';
import '../../domain/repositories/notifications_repository.dart';
import '../../domain/entities/notifications_result.dart';
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
      final models = await _remote.getNotifications(page: page, limit: limit);
      return NotificationsResult.success(models);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<int>> getUnreadCount() async {
    try {
      final count = await _remote.getUnreadCount();
      return NotificationsResult.success(count);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<void>> markAsRead(String notificationId) async {
    try {
      await _remote.markAsRead(notificationId);
      return const NotificationsResult.success(null);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<void>> markAllAsRead() async {
    try {
      await _remote.markAllAsRead();
      return const NotificationsResult.success(null);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<void>> deleteNotification(
    String notificationId,
  ) async {
    try {
      await _remote.deleteNotification(notificationId);
      return const NotificationsResult.success(null);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<NotificationPreferencesEntity>>
      getPreferences() async {
    try {
      final model = await _remote.getPreferences();
      return NotificationsResult.success(model);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<void>> updatePreferences(
    NotificationPreferencesEntity preferences,
  ) async {
    try {
      final model = NotificationPreferencesModel(
        pushEnabled: preferences.pushEnabled,
        emailEnabled: preferences.emailEnabled,
        likesEnabled: preferences.likesEnabled,
        commentsEnabled: preferences.commentsEnabled,
        followsEnabled: preferences.followsEnabled,
        repostsEnabled: preferences.repostsEnabled,
      );
      await _remote.updatePreferences(model);
      return const NotificationsResult.success(null);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<void>> registerDevice({
    required String deviceToken,
    required String platform,
  }) async {
    try {
      await _remote.registerDevice(
        deviceToken: deviceToken,
        platform: platform,
      );
      return const NotificationsResult.success(null);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<NotificationsResult<void>> removeDevice(String deviceId) async {
    try {
      await _remote.removeDevice(deviceId);
      return const NotificationsResult.success(null);
    } on Failure catch (f) {
      return NotificationsResult.failure(f);
    } catch (e) {
      return NotificationsResult.failure(
        const ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Stream<NotificationEntity> get notificationStream =>
      _remote.notificationStream;
}