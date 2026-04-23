import 'message_entity.dart';
import 'participant_entity.dart';

class ConversationEntity {
  final String conversationId;
  final ParticipantEntity participant;
  final MessageEntity? lastMessage;
  final int unreadCount;

  const ConversationEntity({
    required this.conversationId,
    required this.participant,
    required this.lastMessage,
    required this.unreadCount,
  });
}