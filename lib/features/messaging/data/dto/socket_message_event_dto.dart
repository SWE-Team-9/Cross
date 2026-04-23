import '../../domain/entities/messaging_event_type.dart';
import '../../domain/entities/realtime_message_event_entity.dart';
import 'message_dto.dart';

class SocketMessageEventDto {
  final MessagingEventType type;
  final String conversationId;
  final MessageDto message;
  final int currentUnreadCount;

  const SocketMessageEventDto({
    required this.type,
    required this.conversationId,
    required this.message,
    required this.currentUnreadCount,
  });

  factory SocketMessageEventDto.fromJson(Map<String, dynamic> json) {
    final conversationId =
        (json['conversationId'] ?? json['conversation_id'] ?? '').toString();

    final messageMap = json['message'] is Map
        ? Map<String, dynamic>.from(json['message'] as Map)
        : <String, dynamic>{};

    final normalizedMessageMap = <String, dynamic>{
      ...messageMap,
      if (!messageMap.containsKey('conversationId') &&
          !messageMap.containsKey('conversation_id'))
        'conversationId': conversationId,
    };

    return SocketMessageEventDto(
      type: MessagingEventTypeX.fromApi(json['type']),
      conversationId: conversationId,
      message: MessageDto.fromJson(normalizedMessageMap),
      currentUnreadCount: _toInt(
            json['currentUnreadCount'] ?? json['current_unread_count'],
          ) ??
          0,
    );
  }

  RealtimeMessageEventEntity toEntity() {
    return RealtimeMessageEventEntity(
      type: type,
      conversationId: conversationId,
      message: message.toEntity(),
      currentUnreadCount: currentUnreadCount,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}