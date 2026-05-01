import '../entities/conversation_entity.dart';
import '../repositories/messaging_repository.dart';

class GetConversationMetaUseCase {
  final MessagingRepository repository;

  GetConversationMetaUseCase(this.repository);

  Future<ConversationEntity> call(String conversationId) {
    return repository.getConversationMeta(conversationId);
  }
}
