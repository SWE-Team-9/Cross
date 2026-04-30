import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/conversation_messages_page_dto.dart';

void main() {
  group('ConversationMessagesPageDto', () {
    Map<String, dynamic> messageJson({
      String id = 'message-1',
      String? conversationId,
    }) {
      return <String, dynamic>{
        'id': id,
        if (conversationId != null) 'conversationId': conversationId,
        'senderId': 'sender-1',
        'receiverId': 'receiver-1',
        'type': 'TEXT',
        'text': 'Hello',
        'isRead': false,
        'createdAt': '2026-04-30T10:00:00.000Z',
      };
    }

    test('fromJson reads conversationId, page, limit, and messages', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'page': 2,
        'limit': 25,
        'messages': <Map<String, dynamic>>[
          messageJson(id: 'message-1'),
          messageJson(id: 'message-2'),
        ],
      });

      expect(dto.conversationId, 'conversation-1');
      expect(dto.page, 2);
      expect(dto.limit, 25);
      expect(dto.messages, hasLength(2));
      expect(dto.messages.first.id, 'message-1');
    });

    test('fromJson reads snake_case conversation_id', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversation_id': 'conversation-snake',
      });

      expect(dto.conversationId, 'conversation-snake');
    });

    test('fromJson injects page conversationId into messages without one', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'messages': <Map<String, dynamic>>[
          messageJson(id: 'message-1'),
        ],
      });

      expect(dto.messages.single.conversationId, 'conversation-1');
    });

    test('fromJson preserves message conversationId when already present', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-page',
        'messages': <Map<String, dynamic>>[
          messageJson(
            id: 'message-1',
            conversationId: 'conversation-message',
          ),
        ],
      });

      expect(dto.messages.single.conversationId, 'conversation-message');
    });

    test('fromJson parses page and limit from strings', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'page': '3',
        'limit': '15',
      });

      expect(dto.page, 3);
      expect(dto.limit, 15);
    });

    test('fromJson rounds numeric page and limit values', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'page': 2.4,
        'limit': 20.6,
      });

      expect(dto.page, 2);
      expect(dto.limit, 21);
    });

    test('fromJson uses safe defaults', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{});

      expect(dto.conversationId, '');
      expect(dto.page, 1);
      expect(dto.limit, 50);
      expect(dto.messages, isEmpty);
    });

    test('fromJson uses empty messages when messages is not a list', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'messages': 'not-a-list',
      });

      expect(dto.messages, isEmpty);
    });

    test('toEntity maps all fields', () {
      final dto = ConversationMessagesPageDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'page': 1,
        'limit': 50,
        'messages': <Map<String, dynamic>>[
          messageJson(id: 'message-1'),
        ],
      });

      final entity = dto.toEntity();

      expect(entity.conversationId, dto.conversationId);
      expect(entity.page, dto.page);
      expect(entity.limit, dto.limit);
      expect(entity.messages, hasLength(1));
      expect(entity.messages.single.id, 'message-1');
    });
  });
}
