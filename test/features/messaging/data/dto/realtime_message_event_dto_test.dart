import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/realtime_message_event_dto.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';

void main() {
  group('RealtimeMessageEventDto', () {
    Map<String, dynamic> participantJson() {
      return <String, dynamic>{
        'id': 'user-1',
        'displayName': 'Listener One',
        'handle': 'listener',
      };
    }

    Map<String, dynamic> messageJson({
      String conversationId = 'conversation-from-message',
    }) {
      return <String, dynamic>{
        'id': 'message-1',
        'conversationId': conversationId,
        'senderId': 'sender-1',
        'receiverId': 'receiver-1',
        'type': 'TEXT',
        'text': 'Hello',
        'isRead': false,
        'createdAt': '2026-04-30T10:00:00.000Z',
      };
    }

    Map<String, dynamic> conversationJson({
      String conversationId = 'conversation-from-conversation',
    }) {
      return <String, dynamic>{
        'conversationId': conversationId,
        'participant': participantJson(),
        'unreadCount': 2,
      };
    }

    test('fromJson parses NEW_MESSAGE event', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'NEW_MESSAGE',
        'conversationId': 'conversation-1',
        'message': messageJson(conversationId: 'conversation-1'),
      });

      expect(dto.type, RealtimeMessageEventType.newMessage);
      expect(dto.conversationId, 'conversation-1');
      expect(dto.message, isNotNull);
      expect(dto.message!.id, 'message-1');
    });

    test('fromJson parses MESSAGE_CREATED alias', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'MESSAGE_CREATED',
      });

      expect(dto.type, RealtimeMessageEventType.newMessage);
    });

    test('fromJson parses deleted message aliases', () {
      final deleted = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'MESSAGE_DELETED',
        'messageId': 'message-1',
      });

      final deleteAlias = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'DELETE_MESSAGE',
        'deletedMessageId': 'message-2',
      });

      expect(deleted.type, RealtimeMessageEventType.messageDeleted);
      expect(deleted.messageId, 'message-1');
      expect(deleteAlias.type, RealtimeMessageEventType.messageDeleted);
      expect(deleteAlias.messageId, 'message-2');
    });

    test('fromJson parses conversation read aliases', () {
      final read = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'CONVERSATION_READ',
      });

      final markRead = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'MARK_READ',
      });

      expect(read.type, RealtimeMessageEventType.conversationRead);
      expect(markRead.type, RealtimeMessageEventType.conversationRead);
    });

    test('fromJson parses conversation updated aliases', () {
      final updated = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'CONVERSATION_UPDATED',
      });

      final archived = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'CONVERSATION_ARCHIVED',
      });

      final unarchived = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'CONVERSATION_UNARCHIVED',
      });

      expect(updated.type, RealtimeMessageEventType.conversationUpdated);
      expect(archived.type, RealtimeMessageEventType.conversationUpdated);
      expect(unarchived.type, RealtimeMessageEventType.conversationUpdated);
    });

    test('fromJson parses unread, blocked, and unblocked events', () {
      final unread = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'UNREAD_COUNT_UPDATED',
      });

      final blocked = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'BLOCKED',
      });

      final userBlocked = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'USER_BLOCKED',
      });

      final unblocked = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'UNBLOCKED',
      });

      final userUnblocked = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'USER_UNBLOCKED',
      });

      expect(unread.type, RealtimeMessageEventType.unreadCountUpdated);
      expect(blocked.type, RealtimeMessageEventType.userBlocked);
      expect(userBlocked.type, RealtimeMessageEventType.userBlocked);
      expect(unblocked.type, RealtimeMessageEventType.userUnblocked);
      expect(userUnblocked.type, RealtimeMessageEventType.userUnblocked);
    });

    test('fromJson defaults unknown event type', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'SOMETHING_ELSE',
      });

      expect(dto.type, RealtimeMessageEventType.unknown);
    });

    test('fromJson extracts conversationId from message when missing', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'NEW_MESSAGE',
        'message': messageJson(conversationId: 'conversation-from-message'),
      });

      expect(dto.conversationId, 'conversation-from-message');
    });

    test('fromJson extracts conversationId from conversation when missing', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'CONVERSATION_UPDATED',
        'conversation': conversationJson(
          conversationId: 'conversation-from-conversation',
        ),
      });

      expect(dto.conversationId, 'conversation-from-conversation');
    });

    test('fromJson reads snake_case fields', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'UNREAD_COUNT_UPDATED',
        'conversation_id': 'conversation-snake',
        'message_id': 'message-snake',
        'current_unread_count': '4',
        'is_blocked_by_me': 'true',
        'has_blocked_me': '0',
        'can_message': 'false',
        'block_reason': 'privacy',
      });

      expect(dto.conversationId, 'conversation-snake');
      expect(dto.messageId, 'message-snake');
      expect(dto.currentUnreadCount, 4);
      expect(dto.isBlockedByMe, isTrue);
      expect(dto.hasBlockedMe, isFalse);
      expect(dto.canMessage, isFalse);
      expect(dto.blockReason, 'privacy');
    });

    test('fromJson reads unreadCount alias', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'UNREAD_COUNT_UPDATED',
        'unreadCount': 9,
      });

      expect(dto.currentUnreadCount, 9);
    });

    test('fromJson reads unread_count alias', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'UNREAD_COUNT_UPDATED',
        'unread_count': 10,
      });

      expect(dto.currentUnreadCount, 10);
    });

    test('fromJson parses conversation object', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'CONVERSATION_UPDATED',
        'conversation': conversationJson(),
      });

      expect(dto.conversation, isNotNull);
      expect(
          dto.conversation!.conversationId, 'conversation-from-conversation');
    });

    test('fromJson ignores invalid message and conversation values', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'message': 'not-a-map',
        'conversation': 'not-a-map',
      });

      expect(dto.message, isNull);
      expect(dto.conversation, isNull);
    });

    test('toEntity maps all fields', () {
      final dto = RealtimeMessageEventDto.fromJson(<String, dynamic>{
        'type': 'NEW_MESSAGE',
        'conversationId': 'conversation-1',
        'messageId': 'message-1',
        'message': messageJson(conversationId: 'conversation-1'),
        'conversation': conversationJson(conversationId: 'conversation-1'),
        'currentUnreadCount': 5,
        'isBlockedByMe': true,
        'hasBlockedMe': false,
        'canMessage': true,
        'blockReason': 'reason',
      });

      final entity = dto.toEntity();

      expect(entity.type, dto.type);
      expect(entity.conversationId, dto.conversationId);
      expect(entity.messageId, dto.messageId);
      expect(entity.message, isNotNull);
      expect(entity.conversation, isNotNull);
      expect(entity.currentUnreadCount, dto.currentUnreadCount);
      expect(entity.isBlockedByMe, dto.isBlockedByMe);
      expect(entity.hasBlockedMe, dto.hasBlockedMe);
      expect(entity.canMessage, dto.canMessage);
      expect(entity.blockReason, dto.blockReason);
    });
  });
}
