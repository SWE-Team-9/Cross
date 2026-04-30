import 'package:flutter_test/flutter_test.dart';

import 'package:soundcloud_clone/features/messaging/data/dto/conversation_dto.dart';

void main() {
  group('ConversationDto', () {
    Map<String, dynamic> participantJson() {
      return <String, dynamic>{
        'id': 'user-1',
        '_id': 'user-1',
        'userId': 'user-1',
        'username': 'listener',
        'name': 'Listener One',
        'displayName': 'Listener One',
        'avatarUrl': 'https://example.com/avatar.png',
        'avatar': 'https://example.com/avatar.png',
        'profileImageUrl': 'https://example.com/avatar.png',
      };
    }

    Map<String, dynamic> messageJson() {
      return <String, dynamic>{
        'id': 'message-1',
        '_id': 'message-1',
        'messageId': 'message-1',
        'conversationId': 'conversation-1',
        'senderId': 'user-2',
        'receiverId': 'user-1',
        'text': 'Hello',
        'content': 'Hello',
        'type': 'text',
        'createdAt': '2026-04-30T10:00:00.000Z',
        'updatedAt': '2026-04-30T10:01:00.000Z',
        'isMine': false,
        'isRead': true,
      };
    }

    test('fromJson reads camelCase fields', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-1',
        'participant': participantJson(),
        'lastMessage': messageJson(),
        'unreadCount': 3,
        'updatedAt': '2026-04-30T10:10:00.000Z',
        'isArchived': true,
        'isBlockedByMe': false,
        'hasBlockedMe': true,
        'canMessage': false,
        'blockReason': 'blocked_by_receiver',
      });

      expect(dto.conversationId, 'conversation-1');
      expect(dto.participant, isNotNull);
      expect(dto.lastMessage, isNotNull);
      expect(dto.unreadCount, 3);
      expect(dto.updatedAt, DateTime.parse('2026-04-30T10:10:00.000Z'));
      expect(dto.isArchived, isTrue);
      expect(dto.isBlockedByMe, isFalse);
      expect(dto.hasBlockedMe, isTrue);
      expect(dto.canMessage, isFalse);
      expect(dto.blockReason, 'blocked_by_receiver');
    });

    test('fromJson reads fallback id and snake_case fields', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        '_id': 'conversation-2',
        'otherUser': participantJson(),
        'last_message': messageJson(),
        'unread_count': '7',
        'updated_at': '2026-04-30T11:00:00.000Z',
        'is_archived': '1',
        'is_blocked_by_me': 'true',
        'has_blocked_me': '0',
        'can_message': 'false',
        'block_reason': 'privacy',
      });

      expect(dto.conversationId, 'conversation-2');
      expect(dto.lastMessage, isNotNull);
      expect(dto.unreadCount, 7);
      expect(dto.updatedAt, DateTime.parse('2026-04-30T11:00:00.000Z'));
      expect(dto.isArchived, isTrue);
      expect(dto.isBlockedByMe, isTrue);
      expect(dto.hasBlockedMe, isFalse);
      expect(dto.canMessage, isFalse);
      expect(dto.blockReason, 'privacy');
    });

    test('fromJson supports participant aliases', () {
      final fromUser = ConversationDto.fromJson(<String, dynamic>{
        'id': 'conversation-3',
        'user': participantJson(),
      });

      final fromReceiver = ConversationDto.fromJson(<String, dynamic>{
        'id': 'conversation-4',
        'receiver': participantJson(),
      });

      expect(fromUser.conversationId, 'conversation-3');
      expect(fromUser.participant, isNotNull);

      expect(fromReceiver.conversationId, 'conversation-4');
      expect(fromReceiver.participant, isNotNull);
    });

    test('fromJson uses safe defaults for missing optional values', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'participant': participantJson(),
      });

      expect(dto.conversationId, '');
      expect(dto.lastMessage, isNull);
      expect(dto.unreadCount, 0);
      expect(dto.updatedAt, isNull);
      expect(dto.isArchived, isFalse);
      expect(dto.isBlockedByMe, isFalse);
      expect(dto.hasBlockedMe, isFalse);
      expect(dto.canMessage, isTrue);
      expect(dto.blockReason, isNull);
    });

    test('fromJson ignores invalid lastMessage values', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-5',
        'participant': participantJson(),
        'lastMessage': 'not-a-message-map',
      });

      expect(dto.conversationId, 'conversation-5');
      expect(dto.lastMessage, isNull);
    });

    test('fromJson converts numeric booleans and numbers', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'conversationId': 123,
        'participant': participantJson(),
        'unreadCount': 4.8,
        'isArchived': 1,
        'isBlockedByMe': 0,
        'hasBlockedMe': 'TRUE',
        'canMessage': 'FALSE',
      });

      expect(dto.conversationId, '123');
      expect(dto.unreadCount, 4);
      expect(dto.isArchived, isTrue);
      expect(dto.isBlockedByMe, isFalse);
      expect(dto.hasBlockedMe, isTrue);
      expect(dto.canMessage, isFalse);
    });

    test('fromJson returns null updatedAt for invalid dates', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-6',
        'participant': participantJson(),
        'updatedAt': 'not-a-date',
      });

      expect(dto.updatedAt, isNull);
    });

    test('toEntity maps dto fields to entity fields', () {
      final dto = ConversationDto.fromJson(<String, dynamic>{
        'conversationId': 'conversation-7',
        'participant': participantJson(),
        'lastMessage': messageJson(),
        'unreadCount': 9,
        'updatedAt': '2026-04-30T12:00:00.000Z',
        'isArchived': true,
        'isBlockedByMe': true,
        'hasBlockedMe': false,
        'canMessage': false,
        'blockReason': 'blocked',
      });

      final entity = dto.toEntity();

      expect(entity.conversationId, dto.conversationId);
      expect(entity.participant, isNotNull);
      expect(entity.lastMessage, isNotNull);
      expect(entity.unreadCount, dto.unreadCount);
      expect(entity.updatedAt, dto.updatedAt);
      expect(entity.isArchived, dto.isArchived);
      expect(entity.isBlockedByMe, dto.isBlockedByMe);
      expect(entity.hasBlockedMe, dto.hasBlockedMe);
      expect(entity.canMessage, dto.canMessage);
      expect(entity.blockReason, dto.blockReason);
    });
  });
}
