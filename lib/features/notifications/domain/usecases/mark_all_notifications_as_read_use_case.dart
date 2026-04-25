import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class MarkAllNotificationsAsReadUseCase {
  final NotificationsRepository _repository;

  const MarkAllNotificationsAsReadUseCase(this._repository);

  Future<NotificationsResult<void>> call() => _repository.markAllAsRead();
}