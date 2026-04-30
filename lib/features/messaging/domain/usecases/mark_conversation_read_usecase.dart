import '../repositories/messaging_repository.dart';

class MarkConversationReadUseCase {
  final MessagingRepository repository;

  MarkConversationReadUseCase(this.repository);

  Future<void> call(String conversationId) {
    return repository.markConversationAsRead(conversationId);
  }
}
