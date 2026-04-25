import 'conversation_entity.dart';
import 'message_entity.dart';

enum RealtimeMessageEventType {
  newMessage,
  messageDeleted,
  conversationRead,
  conversationUpdated,
  unreadCountUpdated,
  userBlocked,
  userUnblocked,
  unknown,
}

class RealtimeMessageEventEntity {
  final RealtimeMessageEventType type;
  final String conversationId;
  final MessageEntity? message;
  final String? messageId;
  final ConversationEntity? conversation;
  final int? currentUnreadCount;
  final bool? isBlockedByMe;
  final bool? hasBlockedMe;
  final bool? canMessage;
  final String? blockReason;

  const RealtimeMessageEventEntity({
    required this.type,
    required this.conversationId,
    this.message,
    this.messageId,
    this.conversation,
    this.currentUnreadCount,
    this.isBlockedByMe,
    this.hasBlockedMe,
    this.canMessage,
    this.blockReason,
  });
}