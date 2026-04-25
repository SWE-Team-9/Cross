import '../entities/notification_entity.dart';
import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class GetNotificationsUseCase {
  final NotificationsRepository _repository;

  const GetNotificationsUseCase(this._repository);

  Future<NotificationsResult<List<NotificationEntity>>> call({
    int page = 1,
    int limit = 20,
  }) {
    return _repository.getNotifications(page: page, limit: limit);
  }
}