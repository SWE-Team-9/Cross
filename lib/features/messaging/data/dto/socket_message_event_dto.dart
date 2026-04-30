import '../../domain/entities/realtime_message_event_entity.dart';
import 'conversation_dto.dart';
import 'message_dto.dart';

class SocketMessageEventDto {
  final RealtimeMessageEventType type;
  final String conversationId;
  final MessageDto? message;
  final String? messageId;
  final ConversationDto? conversation;
  final int? currentUnreadCount;
  final bool? isBlockedByMe;
  final bool? hasBlockedMe;
  final bool? canMessage;
  final String? blockReason;

  const SocketMessageEventDto({
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

  factory SocketMessageEventDto.fromJson(Map<String, dynamic> json) {
    final type = _parseType(json['type']);

    final messageRaw = json['message'];
    final conversationRaw = json['conversation'];

    return SocketMessageEventDto(
      type: type,
      conversationId: (json['conversationId'] ??
              json['conversation_id'] ??
              _extractConversationIdFromMessage(messageRaw) ??
              _extractConversationIdFromConversation(conversationRaw) ??
              '')
          .toString(),
      message: _messageOrNull(messageRaw),
      messageId:
          (json['messageId'] ?? json['message_id'] ?? json['deletedMessageId'])
              ?.toString(),
      conversation: _conversationOrNull(conversationRaw),
      currentUnreadCount: _toInt(
        json['currentUnreadCount'] ??
            json['current_unread_count'] ??
            json['unreadCount'] ??
            json['unread_count'],
      ),
      isBlockedByMe: _toBool(json['isBlockedByMe'] ?? json['is_blocked_by_me']),
      hasBlockedMe: _toBool(json['hasBlockedMe'] ?? json['has_blocked_me']),
      canMessage: _toBool(json['canMessage'] ?? json['can_message']),
      blockReason: (json['blockReason'] ?? json['block_reason'])?.toString(),
    );
  }

  RealtimeMessageEventEntity toEntity() {
    return RealtimeMessageEventEntity(
      type: type,
      conversationId: conversationId,
      message: message?.toEntity(),
      messageId: messageId,
      conversation: conversation?.toEntity(),
      currentUnreadCount: currentUnreadCount,
      isBlockedByMe: isBlockedByMe,
      hasBlockedMe: hasBlockedMe,
      canMessage: canMessage,
      blockReason: blockReason,
    );
  }

  static RealtimeMessageEventType _parseType(dynamic value) {
    final normalized = (value ?? '').toString().trim().toUpperCase();

    switch (normalized) {
      case 'NEW_MESSAGE':
      case 'MESSAGE_CREATED':
        return RealtimeMessageEventType.newMessage;

      case 'MESSAGE_DELETED':
      case 'DELETE_MESSAGE':
        return RealtimeMessageEventType.messageDeleted;

      case 'CONVERSATION_READ':
      case 'MARK_READ':
        return RealtimeMessageEventType.conversationRead;

      case 'CONVERSATION_UPDATED':
      case 'CONVERSATION_ARCHIVED':
      case 'CONVERSATION_UNARCHIVED':
        return RealtimeMessageEventType.conversationUpdated;

      case 'UNREAD_COUNT_UPDATED':
        return RealtimeMessageEventType.unreadCountUpdated;

      case 'USER_BLOCKED':
      case 'BLOCKED':
        return RealtimeMessageEventType.userBlocked;

      case 'USER_UNBLOCKED':
      case 'UNBLOCKED':
        return RealtimeMessageEventType.userUnblocked;

      default:
        return RealtimeMessageEventType.unknown;
    }
  }

  static MessageDto? _messageOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return MessageDto.fromJson(value);
    if (value is Map) {
      return MessageDto.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static ConversationDto? _conversationOrNull(dynamic value) {
    if (value == null) return null;
    if (value is Map<String, dynamic>) return ConversationDto.fromJson(value);
    if (value is Map) {
      return ConversationDto.fromJson(Map<String, dynamic>.from(value));
    }
    return null;
  }

  static String? _extractConversationIdFromMessage(dynamic value) {
    if (value is Map) {
      return (value['conversationId'] ?? value['conversation_id'])?.toString();
    }
    return null;
  }

  static String? _extractConversationIdFromConversation(dynamic value) {
    if (value is Map) {
      return (value['conversationId'] ??
              value['conversation_id'] ??
              value['id'])
          ?.toString();
    }
    return null;
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value.toString());
  }

  static bool? _toBool(dynamic value) {
    if (value == null) return null;
    if (value is bool) return value;

    final normalized = value.toString().trim().toLowerCase();
    if (normalized == 'true' || normalized == '1') return true;
    if (normalized == 'false' || normalized == '0') return false;

    return null;
  }
}
