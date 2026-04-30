import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';

void main() {
  group('ConversationListPageEntity', () {
    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: '@listener',
      avatarUrl: null,
    );

    const conversation = ConversationEntity(
      conversationId: 'conversation-1',
      participant: participant,
      lastMessage: null,
      unreadCount: 0,
    );

    test('stores all provided values', () {
      const entity = ConversationListPageEntity(
        conversations: <ConversationEntity>[conversation],
        page: 2,
        limit: 20,
        total: 35,
        hasMore: true,
      );

      expect(entity.conversations, <ConversationEntity>[conversation]);
      expect(entity.page, 2);
      expect(entity.limit, 20);
      expect(entity.total, 35);
      expect(entity.hasMore, isTrue);
    });

    test('allows empty conversations list', () {
      const entity = ConversationListPageEntity(
        conversations: <ConversationEntity>[],
        page: 1,
        limit: 20,
        total: 0,
        hasMore: false,
      );

      expect(entity.conversations, isEmpty);
      expect(entity.hasMore, isFalse);
    });
  });
}
