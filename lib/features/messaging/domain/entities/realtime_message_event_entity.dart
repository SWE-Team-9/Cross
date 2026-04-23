import 'message_entity.dart';
import 'messaging_event_type.dart';

class RealtimeMessageEventEntity {
  final MessagingEventType type;
  final String conversationId;
  final MessageEntity message;
  final int currentUnreadCount;

  const RealtimeMessageEventEntity({
    required this.type,
    required this.conversationId,
    required this.message,
    required this.currentUnreadCount,
  });
}