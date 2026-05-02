import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';

void main() {
  group('ConversationMessagesPageEntity', () {
    MessageEntity message(String id) {
      return MessageEntity(
        id: id,
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.text,
        text: 'Hello',
        isRead: false,
        createdAt: DateTime.utc(2026, 4, 30, 10),
        sharedTrack: null,
        sharedPlaylist: null,
      );
    }

    test('stores all provided values', () {
      final messages = <MessageEntity>[
        message('message-1'),
        message('message-2'),
      ];

      final entity = ConversationMessagesPageEntity(
        conversationId: 'conversation-1',
        page: 2,
        limit: 10,
        messages: messages,
      );

      expect(entity.conversationId, 'conversation-1');
      expect(entity.page, 2);
      expect(entity.limit, 10);
      expect(entity.messages, messages);
    });

    test('hasMore is true when messages length is equal to limit', () {
      final entity = ConversationMessagesPageEntity(
        conversationId: 'conversation-1',
        page: 1,
        limit: 2,
        messages: <MessageEntity>[
          message('message-1'),
          message('message-2'),
        ],
      );

      expect(entity.hasMore, isTrue);
    });

    test('hasMore is true when messages length is greater than limit', () {
      final entity = ConversationMessagesPageEntity(
        conversationId: 'conversation-1',
        page: 1,
        limit: 1,
        messages: <MessageEntity>[
          message('message-1'),
          message('message-2'),
        ],
      );

      expect(entity.hasMore, isTrue);
    });

    test('hasMore is false when messages length is less than limit', () {
      final entity = ConversationMessagesPageEntity(
        conversationId: 'conversation-1',
        page: 1,
        limit: 3,
        messages: <MessageEntity>[
          message('message-1'),
          message('message-2'),
        ],
      );

      expect(entity.hasMore, isFalse);
    });

    test('hasMore is false for empty messages when limit is positive', () {
      const entity = ConversationMessagesPageEntity(
        conversationId: 'conversation-1',
        page: 1,
        limit: 50,
        messages: <MessageEntity>[],
      );

      expect(entity.hasMore, isFalse);
    });
  });
}
