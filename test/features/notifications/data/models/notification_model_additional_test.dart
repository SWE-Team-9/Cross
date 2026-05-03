import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/notifications/data/models/notification_model.dart';

void main() {
  group('NotificationModel additional cases', () {
    test('falls back to "Someone" when actor info missing', () {
      final model = NotificationModel.fromJson({
        'id': 'n10',
        'type': 'like',
        'message': '',
        'actor': {},
        'target': {'title': 'Hidden Gem'},
        'entityType': 'track',
        'entityId': 'trk_10',
        'createdAt': '2026-03-07T10:20:00Z',
      });

      expect(model.actorDisplayName, '');
      expect(model.actorHandle, '');
      expect(model.actorId, '');
      expect(model.message, 'Someone liked your track Hidden Gem');
    });

    test('extractTrackFromMessage finds after "track" phrase', () {
      final model = NotificationModel.fromJson({
        'id': 'n11',
        'type': 'repost',
        'message': 'They reposted track The Hidden One',
        'actorHandle': 'u1',
        'entityType': 'track',
        'entityId': 'trk_11',
        'createdAt': '2026-03-07T10:20:00Z',
      });

      expect(model.trackName, 'The Hidden One');
      expect(model.message, contains('reposted'));
    });
  });
}
