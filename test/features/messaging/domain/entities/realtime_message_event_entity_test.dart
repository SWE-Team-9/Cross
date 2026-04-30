import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';

void main() {
  group('RealtimeMessageEventEntity', () {
    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: '@listener',
      avatarUrl: null,
    );

    final message = MessageEntity(
      id: 'message-1',
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

    final conversation = ConversationEntity(
      conversationId: 'conversation-1',
      participant: participant,
      lastMessage: message,
      unreadCount: 1,
    );

    test('stores required values', () {
      const entity = RealtimeMessageEventEntity(
        type: RealtimeMessageEventType.unknown,
        conversationId: 'conversation-1',
      );

      expect(entity.type, RealtimeMessageEventType.unknown);
      expect(entity.conversationId, 'conversation-1');
      expect(entity.message, isNull);
      expect(entity.messageId, isNull);
      expect(entity.conversation, isNull);
      expect(entity.currentUnreadCount, isNull);
      expect(entity.isBlockedByMe, isNull);
      expect(entity.hasBlockedMe, isNull);
      expect(entity.canMessage, isNull);
      expect(entity.blockReason, isNull);
    });

    test('stores all optional values', () {
      final entity = RealtimeMessageEventEntity(
        type: RealtimeMessageEventType.newMessage,
        conversationId: 'conversation-1',
        message: message,
        messageId: 'message-1',
        conversation: conversation,
        currentUnreadCount: 5,
        isBlockedByMe: true,
        hasBlockedMe: false,
        canMessage: true,
        blockReason: 'privacy',
      );

      expect(entity.type, RealtimeMessageEventType.newMessage);
      expect(entity.conversationId, 'conversation-1');
      expect(entity.message, message);
      expect(entity.messageId, 'message-1');
      expect(entity.conversation, conversation);
      expect(entity.currentUnreadCount, 5);
      expect(entity.isBlockedByMe, isTrue);
      expect(entity.hasBlockedMe, isFalse);
      expect(entity.canMessage, isTrue);
      expect(entity.blockReason, 'privacy');
    });

    test('enum includes all expected event types', () {
      expect(
        RealtimeMessageEventType.values,
        containsAll(<RealtimeMessageEventType>[
          RealtimeMessageEventType.newMessage,
          RealtimeMessageEventType.messageDeleted,
          RealtimeMessageEventType.conversationRead,
          RealtimeMessageEventType.conversationUpdated,
          RealtimeMessageEventType.unreadCountUpdated,
          RealtimeMessageEventType.userBlocked,
          RealtimeMessageEventType.userUnblocked,
          RealtimeMessageEventType.unknown,
        ]),
      );
    });
  });
}
