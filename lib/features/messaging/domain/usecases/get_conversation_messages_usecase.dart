import '../entities/conversation_messages_page_entity.dart';
import '../repositories/messaging_repository.dart';

class GetConversationMessagesUseCase {
  final MessagingRepository repository;

  GetConversationMessagesUseCase(this.repository);

  Future<ConversationMessagesPageEntity> call(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) {
    return repository.getConversationMessages(
      conversationId,
      page: page,
      limit: limit,
    );
  }
}