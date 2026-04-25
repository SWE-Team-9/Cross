import '../repositories/messaging_repository.dart';

class ArchiveConversationUseCase {
  final MessagingRepository repository;

  ArchiveConversationUseCase(this.repository);

  Future<void> call(String conversationId) {
    return repository.archiveConversation(conversationId);
  }
}