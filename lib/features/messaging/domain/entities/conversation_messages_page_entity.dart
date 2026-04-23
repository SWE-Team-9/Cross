import 'message_entity.dart';

class ConversationMessagesPageEntity {
  final String conversationId;
  final int page;
  final int limit;
  final List<MessageEntity> messages;

  const ConversationMessagesPageEntity({
    required this.conversationId,
    required this.page,
    required this.limit,
    required this.messages,
  });

  bool get hasMore => messages.length >= limit;
}