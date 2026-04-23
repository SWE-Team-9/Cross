import '../../domain/entities/conversation_entity.dart';
import 'message_dto.dart';
import 'participant_dto.dart';

class ConversationDto {
  final String conversationId;
  final ParticipantDto participant;
  final MessageDto? lastMessage;
  final int unreadCount;

  const ConversationDto({
    required this.conversationId,
    required this.participant,
    required this.lastMessage,
    required this.unreadCount,
  });

  factory ConversationDto.fromJson(Map<String, dynamic> json) {
    final participantMap = json['participant'] is Map
        ? Map<String, dynamic>.from(json['participant'] as Map)
        : <String, dynamic>{};

    final conversationId =
        (json['conversationId'] ?? json['conversation_id'] ?? '').toString();

    final lastMessageMap = json['lastMessage'] is Map
        ? Map<String, dynamic>.from(json['lastMessage'] as Map)
        : null;

    final normalizedLastMessageMap = lastMessageMap == null
        ? null
        : <String, dynamic>{
            ...lastMessageMap,
            if (!lastMessageMap.containsKey('conversationId') &&
                !lastMessageMap.containsKey('conversation_id'))
              'conversationId': conversationId,
          };

    return ConversationDto(
      conversationId: conversationId,
      participant: ParticipantDto.fromJson(participantMap),
      lastMessage: normalizedLastMessageMap == null
          ? null
          : MessageDto.fromJson(normalizedLastMessageMap),
      unreadCount:
          _toInt(json['unreadCount'] ?? json['unread_count'] ?? json['count']) ??
              0,
    );
  }

  ConversationEntity toEntity() {
    return ConversationEntity(
      conversationId: conversationId,
      participant: participant.toEntity(),
      lastMessage: lastMessage?.toEntity(),
      unreadCount: unreadCount,
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}