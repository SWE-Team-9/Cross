import 'conversation_entity.dart';

class ConversationListPageEntity {
  final int page;
  final int limit;
  final int total;
  final List<ConversationEntity> conversations;

  const ConversationListPageEntity({
    required this.page,
    required this.limit,
    required this.total,
    required this.conversations,
  });

  bool get hasMore => page * limit < total;
}