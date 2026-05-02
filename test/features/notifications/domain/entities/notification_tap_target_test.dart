import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_tap_target.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';

void main() {
  group('NotificationTapTarget sealed classes', () {
    test('NotificationCommentsTapTarget stores trackId', () {
      final target = NotificationCommentsTapTarget(trackId: 'trk-123');
      expect(target.trackId, 'trk-123');
      expect(target, isA<NotificationTapTarget>());
    });

    test('NotificationProfileTapTarget stores handle', () {
      final target = NotificationProfileTapTarget(handle: 'my_user');
      expect(target.handle, 'my_user');
      expect(target, isA<NotificationTapTarget>());
    });

    test('NotificationConversationTapTarget stores conversation', () {
      final convo = ConversationEntity(
        conversationId: 'conv-1',
        participant: ParticipantEntity(
          id: 'u1',
          displayName: 'User 1',
          handle: 'user1',
          avatarUrl: null,
        ),
        lastMessage: null,
        unreadCount: 0,
      );

      final target = NotificationConversationTapTarget(conversation: convo);
      expect(target.conversation.conversationId, 'conv-1');
      expect(target, isA<NotificationTapTarget>());
    });

    test('Tap targets can be checked with is operator', () {
      final comments = NotificationCommentsTapTarget(trackId: 'trk-1');
      final profile = NotificationProfileTapTarget(handle: 'user');

      expect(comments, isA<NotificationCommentsTapTarget>());
      expect(profile, isA<NotificationProfileTapTarget>());
      expect(comments, isNot(isA<NotificationProfileTapTarget>()));
    });
  });
}
