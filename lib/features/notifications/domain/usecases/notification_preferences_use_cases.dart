import '../entities/notification_preferences_entity.dart';
import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class GetNotificationPreferencesUseCase {
  final NotificationsRepository _repository;

  const GetNotificationPreferencesUseCase(this._repository);

  Future<NotificationsResult<NotificationPreferencesEntity>> call() =>
      _repository.getPreferences();
}

class UpdateNotificationPreferencesUseCase {
  final NotificationsRepository _repository;

  const UpdateNotificationPreferencesUseCase(this._repository);

  Future<NotificationsResult<void>> call(
    NotificationPreferencesEntity preferences,
  ) =>
      _repository.updatePreferences(preferences);
}