import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class MarkNotificationAsReadUseCase {
  final NotificationsRepository _repository;

  const MarkNotificationAsReadUseCase(this._repository);

  Future<NotificationsResult<void>> call(String notificationId) =>
      _repository.markAsRead(notificationId);
}