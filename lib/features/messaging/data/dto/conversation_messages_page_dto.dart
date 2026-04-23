import '../../domain/entities/conversation_messages_page_entity.dart';
import 'message_dto.dart';

class ConversationMessagesPageDto {
  final String conversationId;
  final int page;
  final int limit;
  final List<MessageDto> messages;

  const ConversationMessagesPageDto({
    required this.conversationId,
    required this.page,
    required this.limit,
    required this.messages,
  });

  factory ConversationMessagesPageDto.fromJson(Map<String, dynamic> json) {
    final conversationId =
        (json['conversationId'] ?? json['conversation_id'] ?? '').toString();

    final rawList = json['messages'] is List
        ? List<dynamic>.from(json['messages'] as List)
        : const <dynamic>[];

    final normalizedMessages = rawList.map((item) {
      final map = Map<String, dynamic>.from(item as Map);
      if (!map.containsKey('conversationId') &&
          !map.containsKey('conversation_id')) {
        map['conversationId'] = conversationId;
      }
      return MessageDto.fromJson(map);
    }).toList(growable: false);

    return ConversationMessagesPageDto(
      conversationId: conversationId,
      page: _toInt(json['page']) ?? 1,
      limit: _toInt(json['limit']) ?? 50,
      messages: normalizedMessages,
    );
  }

  ConversationMessagesPageEntity toEntity() {
    return ConversationMessagesPageEntity(
      conversationId: conversationId,
      page: page,
      limit: limit,
      messages: messages.map((e) => e.toEntity()).toList(
            growable: false,
          ),
    );
  }

  static int? _toInt(dynamic value) {
    if (value == null) return null;
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse(value.toString());
  }
}