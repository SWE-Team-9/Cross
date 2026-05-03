import '../repositories/messaging_repository.dart';

class DeleteConversationUseCase {
  final MessagingRepository repository;

  DeleteConversationUseCase(this.repository);

  Future<void> call(String conversationId) {
    return repository.deleteConversation(conversationId);
  }
}