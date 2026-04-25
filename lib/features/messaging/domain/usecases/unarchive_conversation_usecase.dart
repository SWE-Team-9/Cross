import '../repositories/messaging_repository.dart';

class UnarchiveConversationUseCase {
  final MessagingRepository repository;

  UnarchiveConversationUseCase(this.repository);

  Future<void> call(String conversationId) {
    return repository.unarchiveConversation(conversationId);
  }
}