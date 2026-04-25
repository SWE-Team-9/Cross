import '../entities/conversation_entity.dart';
import '../repositories/messaging_repository.dart';

class GetOrCreateDirectConversationUseCase {
  final MessagingRepository repository;

  GetOrCreateDirectConversationUseCase(this.repository);

  Future<ConversationEntity> call({
    required String receiverId,
  }) {
    return repository.getOrCreateDirectConversation(
      receiverId: receiverId,
    );
  }
}