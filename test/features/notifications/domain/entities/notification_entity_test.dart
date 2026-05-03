import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('NotificationEntity', () {
    test('copyWith updates only specified fields', () {
      final original = NotificationEntity(
        id: 'n1',
        type: NotificationType.like,
        message: 'User liked your track',
        actorId: 'user1',
        actorDisplayName: 'User One',
        actorHandle: 'user1_handle',
        actorAvatarUrl: 'https://avatar.png',
        entityType: 'track',
        entityId: 'track1',
        trackName: 'My Track',
        isRead: false,
        createdAt: DateTime(2026, 3, 7, 10, 20),
      );

      final updated =
          original.copyWith(isRead: true, message: 'Marked as read');

      expect(updated.id, 'n1');
      expect(updated.isRead, true);
      expect(updated.message, 'Marked as read');
      expect(updated.type, NotificationType.like);
      expect(updated.actorId, 'user1');
    });

    test('NotificationType.fromString parses all variants', () {
      expect(NotificationType.fromString('like'), NotificationType.like);
      expect(NotificationType.fromString('comment'), NotificationType.comment);
      expect(NotificationType.fromString('follow'), NotificationType.follow);
      expect(NotificationType.fromString('repost'), NotificationType.repost);
      expect(NotificationType.fromString('message'), NotificationType.message);
      expect(NotificationType.fromString('unknown_type'),
          NotificationType.unknown);
    });

    test('NotificationType.fromString case-insensitive parsing', () {
      expect(NotificationType.fromString('LIKE'), NotificationType.like);
      expect(NotificationType.fromString('Comment'), NotificationType.comment);
      expect(
          NotificationType.fromString('NEW_MESSAGE'), NotificationType.message);
    });

    test('NotificationEntity equality via props', () {
      final n1 = NotificationEntity(
        id: 'n1',
        type: NotificationType.like,
        message: 'liked',
        actorId: 'u1',
        actorDisplayName: '',
        actorHandle: '',
        actorAvatarUrl: '',
        entityType: 'track',
        entityId: 'trk1',
        trackName: '',
        isRead: false,
        createdAt: DateTime(2026, 3, 7),
      );

      final n2 = NotificationEntity(
        id: 'n1',
        type: NotificationType.like,
        message: 'liked',
        actorId: 'u1',
        actorDisplayName: '',
        actorHandle: '',
        actorAvatarUrl: '',
        entityType: 'track',
        entityId: 'trk1',
        trackName: '',
        isRead: false,
        createdAt: DateTime(2026, 3, 7),
      );

      expect(n1, n2);
    });
  });
}
