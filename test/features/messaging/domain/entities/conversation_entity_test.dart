import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';

void main() {
  group('ConversationEntity', () {
    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: '@listener',
      avatarUrl: null,
    );

    final updatedAt = DateTime.utc(2026, 4, 30, 10);

    final lastMessage = MessageEntity(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'receiver-1',
      type: MessageType.text,
      text: 'Hello',
      isRead: false,
      createdAt: DateTime.utc(2026, 4, 30, 9),
      sharedTrack: null,
      sharedPlaylist: null,
    );

    ConversationEntity buildSubject() {
      return ConversationEntity(
        conversationId: 'conversation-1',
        participant: participant,
        lastMessage: lastMessage,
        unreadCount: 3,
        updatedAt: updatedAt,
        isArchived: true,
        isBlockedByMe: true,
        hasBlockedMe: false,
        canMessage: false,
        blockReason: 'blocked',
      );
    }

    test('stores all provided values', () {
      final entity = buildSubject();

      expect(entity.conversationId, 'conversation-1');
      expect(entity.participant, participant);
      expect(entity.lastMessage, lastMessage);
      expect(entity.unreadCount, 3);
      expect(entity.updatedAt, updatedAt);
      expect(entity.isArchived, isTrue);
      expect(entity.isBlockedByMe, isTrue);
      expect(entity.hasBlockedMe, isFalse);
      expect(entity.canMessage, isFalse);
      expect(entity.blockReason, 'blocked');
    });

    test('uses default values for optional status fields', () {
      const entity = ConversationEntity(
        conversationId: 'conversation-1',
        participant: participant,
        lastMessage: null,
        unreadCount: 0,
      );

      expect(entity.updatedAt, isNull);
      expect(entity.isArchived, isFalse);
      expect(entity.isBlockedByMe, isFalse);
      expect(entity.hasBlockedMe, isFalse);
      expect(entity.canMessage, isTrue);
      expect(entity.blockReason, isNull);
    });

    test('copyWith keeps existing values when no arguments are provided', () {
      final entity = buildSubject();
      final copy = entity.copyWith();

      expect(copy.conversationId, entity.conversationId);
      expect(copy.participant, entity.participant);
      expect(copy.lastMessage, entity.lastMessage);
      expect(copy.unreadCount, entity.unreadCount);
      expect(copy.updatedAt, entity.updatedAt);
      expect(copy.isArchived, entity.isArchived);
      expect(copy.isBlockedByMe, entity.isBlockedByMe);
      expect(copy.hasBlockedMe, entity.hasBlockedMe);
      expect(copy.canMessage, entity.canMessage);
      expect(copy.blockReason, entity.blockReason);
    });

    test('copyWith overrides provided values', () {
      final entity = buildSubject();

      const newParticipant = ParticipantEntity(
        id: 'user-2',
        displayName: 'Listener Two',
        handle: '@listener2',
        avatarUrl: 'https://example.com/avatar.png',
      );

      final newMessage = MessageEntity(
        id: 'message-2',
        conversationId: 'conversation-2',
        senderId: 'sender-2',
        receiverId: 'receiver-2',
        type: MessageType.trackShare,
        text: null,
        isRead: true,
        createdAt: DateTime.utc(2026, 4, 30, 11),
        sharedTrack: null,
        sharedPlaylist: null,
      );

      final newUpdatedAt = DateTime.utc(2026, 4, 30, 12);

      final copy = entity.copyWith(
        conversationId: 'conversation-2',
        participant: newParticipant,
        lastMessage: newMessage,
        unreadCount: 10,
        updatedAt: newUpdatedAt,
        isArchived: false,
        isBlockedByMe: false,
        hasBlockedMe: true,
        canMessage: true,
        blockReason: 'privacy',
      );

      expect(copy.conversationId, 'conversation-2');
      expect(copy.participant, newParticipant);
      expect(copy.lastMessage, newMessage);
      expect(copy.unreadCount, 10);
      expect(copy.updatedAt, newUpdatedAt);
      expect(copy.isArchived, isFalse);
      expect(copy.isBlockedByMe, isFalse);
      expect(copy.hasBlockedMe, isTrue);
      expect(copy.canMessage, isTrue);
      expect(copy.blockReason, 'privacy');
    });

    test('copyWith clearLastMessage clears lastMessage', () {
      final entity = buildSubject();

      final copy = entity.copyWith(clearLastMessage: true);

      expect(copy.lastMessage, isNull);
    });

    test('copyWith clearUpdatedAt clears updatedAt', () {
      final entity = buildSubject();

      final copy = entity.copyWith(clearUpdatedAt: true);

      expect(copy.updatedAt, isNull);
    });

    test('copyWith clearBlockReason clears blockReason', () {
      final entity = buildSubject();

      final copy = entity.copyWith(clearBlockReason: true);

      expect(copy.blockReason, isNull);
    });

    test('copyWith clear flags take precedence over provided nullable values',
        () {
      final entity = buildSubject();

      final copy = entity.copyWith(
        lastMessage: lastMessage,
        clearLastMessage: true,
        updatedAt: updatedAt,
        clearUpdatedAt: true,
        blockReason: 'new reason',
        clearBlockReason: true,
      );

      expect(copy.lastMessage, isNull);
      expect(copy.updatedAt, isNull);
      expect(copy.blockReason, isNull);
    });
  });
}
