import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/conversation_list_page_dto.dart';

void main() {
  group('ConversationListPageDto', () {
    Map<String, dynamic> participantJson() {
      return <String, dynamic>{
        'id': 'user-1',
        'displayName': 'Listener One',
        'handle': 'listener',
      };
    }

    Map<String, dynamic> conversationJson({
      String id = 'conversation-1',
    }) {
      return <String, dynamic>{
        'conversationId': id,
        'participant': participantJson(),
        'unreadCount': 2,
        'updatedAt': '2026-04-30T10:00:00.000Z',
      };
    }

    test('fromJson reads conversations list', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': <Map<String, dynamic>>[
          conversationJson(id: 'conversation-1'),
          conversationJson(id: 'conversation-2'),
        ],
        'page': 1,
        'limit': 20,
        'total': 2,
        'hasMore': false,
      });

      expect(dto.conversations, hasLength(2));
      expect(dto.conversations.first.conversationId, 'conversation-1');
      expect(dto.page, 1);
      expect(dto.limit, 20);
      expect(dto.total, 2);
      expect(dto.hasMore, isFalse);
    });

    test('fromJson reads items, results, and data aliases', () {
      final fromItems = ConversationListPageDto.fromJson(<String, dynamic>{
        'items': <Map<String, dynamic>>[
          conversationJson(id: 'from-items'),
        ],
      });

      final fromResults = ConversationListPageDto.fromJson(<String, dynamic>{
        'results': <Map<String, dynamic>>[
          conversationJson(id: 'from-results'),
        ],
      });

      final fromData = ConversationListPageDto.fromJson(<String, dynamic>{
        'data': <Map<String, dynamic>>[
          conversationJson(id: 'from-data'),
        ],
      });

      expect(fromItems.conversations.single.conversationId, 'from-items');
      expect(fromResults.conversations.single.conversationId, 'from-results');
      expect(fromData.conversations.single.conversationId, 'from-data');
    });

    test('fromJson filters out non-map list items', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': <dynamic>[
          conversationJson(id: 'valid'),
          'invalid',
          123,
          null,
        ],
      });

      expect(dto.conversations, hasLength(1));
      expect(dto.conversations.single.conversationId, 'valid');
    });

    test('fromJson defaults to empty list when raw list is not a list', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': 'not-a-list',
      });

      expect(dto.conversations, isEmpty);
    });

    test('fromJson parses numeric pagination values from strings', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': <Map<String, dynamic>>[
          conversationJson(),
        ],
        'page': '2',
        'limit': '10',
        'total': '25',
      });

      expect(dto.page, 2);
      expect(dto.limit, 10);
      expect(dto.total, 25);
      expect(dto.hasMore, isTrue);
    });

    test('fromJson converts num pagination values to int', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': <Map<String, dynamic>>[
          conversationJson(),
        ],
        'page': 2.9,
        'limit': 10.9,
        'total': 20.2,
      });

      expect(dto.page, 2);
      expect(dto.limit, 10);
      expect(dto.total, 20);
    });

    test('fromJson reads has_more alias and bool-like strings', () {
      final trueDto = ConversationListPageDto.fromJson(<String, dynamic>{
        'has_more': '1',
      });

      final falseDto = ConversationListPageDto.fromJson(<String, dynamic>{
        'hasMore': 'false',
      });

      expect(trueDto.hasMore, isTrue);
      expect(falseDto.hasMore, isFalse);
    });

    test('fromJson computes hasMore when not explicitly provided', () {
      final hasMore = ConversationListPageDto.fromJson(<String, dynamic>{
        'page': 1,
        'limit': 10,
        'total': 11,
      });

      final noMore = ConversationListPageDto.fromJson(<String, dynamic>{
        'page': 2,
        'limit': 10,
        'total': 20,
      });

      expect(hasMore.hasMore, isTrue);
      expect(noMore.hasMore, isFalse);
    });

    test('fromJson uses safe pagination defaults', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': <Map<String, dynamic>>[
          conversationJson(id: 'conversation-1'),
          conversationJson(id: 'conversation-2'),
        ],
      });

      expect(dto.page, 1);
      expect(dto.limit, 2);
      expect(dto.total, 2);
      expect(dto.hasMore, isFalse);
    });

    test('toEntity maps all fields', () {
      final dto = ConversationListPageDto.fromJson(<String, dynamic>{
        'conversations': <Map<String, dynamic>>[
          conversationJson(id: 'conversation-1'),
        ],
        'page': 1,
        'limit': 20,
        'total': 1,
        'hasMore': false,
      });

      final entity = dto.toEntity();

      expect(entity.conversations, hasLength(1));
      expect(entity.conversations.single.conversationId, 'conversation-1');
      expect(entity.page, dto.page);
      expect(entity.limit, dto.limit);
      expect(entity.total, dto.total);
      expect(entity.hasMore, dto.hasMore);
    });
  });
}
