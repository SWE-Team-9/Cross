import '../entities/conversation_list_page_entity.dart';
import '../repositories/messaging_repository.dart';

class GetConversationsUseCase {
  final MessagingRepository repository;

  GetConversationsUseCase(this.repository);

  Future<ConversationListPageEntity> call({
    int page = 1,
    int limit = 20,
    bool archived = false,
  }) {
    return repository.getMyConversations(
      page: page,
      limit: limit,
      archived: archived,
    );
  }
}
