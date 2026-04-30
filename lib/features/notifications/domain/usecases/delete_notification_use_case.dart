import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class DeleteNotificationUseCase {
  final NotificationsRepository _repository;

  const DeleteNotificationUseCase(this._repository);

  Future<NotificationsResult<void>> call(String notificationId) =>
      _repository.deleteNotification(notificationId);
}
