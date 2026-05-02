import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';

void main() {
  group('NotificationModel.fromJson edge cases', () {
    test('empty actor map with no top-level actor data', () {
      final model = NotificationModel.fromJson({
        'id': 'n_edge1',
        'type': 'like',
        'message': 'Someone liked something',
        'actor': {},
        'target': {},
        'entityType': 'track',
        'entityId': 'trk_unknown',
        'createdAt': '2026-03-07T10:20:00Z',
      });

      expect(model.actorId, '');
      expect(model.actorDisplayName, '');
      expect(model.actorHandle, '');
      expect(model.message, 'Someone liked something');
    });

    test('handles deeply nested payload structures', () {
      final model = NotificationModel.fromJson({
        'id': 'n_deep',
        'type': 'comment',
        'message': 'commented',
        'actor': {
          'handle': 'user_deep',
          'displayName': 'Deep User',
        },
        'target': {
          'type': 'track',
          'entity': {
            'title': 'Nested Track',
          },
        },
        'entityType': 'track',
        'entityId': 'trk_deep',
        'createdAt': '2026-03-07T10:20:00Z',
      });

      expect(model.actorHandle, 'user_deep');
      expect(model.actorDisplayName, 'Deep User');
      expect(model.trackName, 'Nested Track');
    });

    test('toJson round-trip preserves data', () {
      final original = NotificationModel.fromJson({
        'id': 'n_roundtrip',
        'type': 'repost',
        'message': 'reposted your track',
        'actor': {
          'handle': 'reposter',
          'displayName': 'Reposter User',
          'avatarUrl': 'https://avatar.example.com/rep.jpg',
        },
        'target': {'title': 'Original Track'},
        'entityType': 'track',
        'entityId': 'trk_original',
        'isRead': true,
        'createdAt': '2026-03-07T10:20:00Z',
      });

      final json = original.toJson();
      final restored = NotificationModel.fromJson(json);

      expect(restored.id, original.id);
      expect(restored.type, original.type);
      expect(restored.actorHandle, original.actorHandle);
      expect(restored.message, original.message);
      expect(restored.isRead, original.isRead);
    });

    test('handles message notifications with actor fallback', () {
      final model = NotificationModel.fromJson({
        'id': 'n_msg',
        'type': 'message',
        'message': 'New message from someone',
        'actorId': 'user_sender',
        'entityType': 'user',
        'entityId': 'user_sender',
        'createdAt': '2026-03-07T10:20:00Z',
      });

      expect(model.type, NotificationType.message);
      expect(model.actorId, 'user_sender');
    });

    test('handles follow notifications with target as user', () {
      final model = NotificationModel.fromJson({
        'id': 'n_follow',
        'type': 'follow',
        'message': 'Someone followed you',
        'actor': {'handle': 'follower_user'},
        'target': {
          'type': 'user',
          'handle': 'your_handle',
        },
        'entityType': 'user',
        'createdAt': '2026-03-07T10:20:00Z',
      });

      expect(model.type, NotificationType.follow);
      expect(model.entityType, 'user');
      expect(model.entityId, 'your_handle');
    });
  });
}
