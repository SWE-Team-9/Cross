import '../repositories/notifications_repository.dart';
import '../entities/notifications_result.dart';

class GetUnreadCountUseCase {
  final NotificationsRepository _repository;

  const GetUnreadCountUseCase(this._repository);

  Future<NotificationsResult<int>> call() => _repository.getUnreadCount();
}