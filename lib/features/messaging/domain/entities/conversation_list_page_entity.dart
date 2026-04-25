import 'conversation_entity.dart';

class ConversationListPageEntity {
  final List<ConversationEntity> conversations;
  final int page;
  final int limit;
  final int total;
  final bool hasMore;

  const ConversationListPageEntity({
    required this.conversations,
    required this.page,
    required this.limit,
    required this.total,
    required this.hasMore,
  });
}