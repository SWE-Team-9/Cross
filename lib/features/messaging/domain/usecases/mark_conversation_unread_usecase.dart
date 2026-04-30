import '../repositories/messaging_repository.dart';

class MarkConversationUnreadUseCase {
  final MessagingRepository repository;

  MarkConversationUnreadUseCase(this.repository);

  Future<void> call(String conversationId) {
    return repository.markConversationAsUnread(conversationId);
  }
}
