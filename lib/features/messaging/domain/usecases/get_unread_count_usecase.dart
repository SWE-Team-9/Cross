import '../entities/unread_count_entity.dart';
import '../repositories/messaging_repository.dart';

class GetUnreadCountUseCase {
  final MessagingRepository repository;

  GetUnreadCountUseCase(this.repository);

  Future<UnreadCountEntity> call() {
    return repository.getUnreadCount();
  }
}