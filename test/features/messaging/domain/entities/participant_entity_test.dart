import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';

void main() {
  group('ParticipantEntity', () {
    test('stores all provided values', () {
      const entity = ParticipantEntity(
        id: 'user-1',
        displayName: 'Listener One',
        handle: '@listener',
        avatarUrl: 'https://example.com/avatar.png',
      );

      expect(entity.id, 'user-1');
      expect(entity.displayName, 'Listener One');
      expect(entity.handle, '@listener');
      expect(entity.avatarUrl, 'https://example.com/avatar.png');
    });

    test('allows null avatarUrl', () {
      const entity = ParticipantEntity(
        id: 'user-1',
        displayName: 'Listener One',
        handle: '@listener',
        avatarUrl: null,
      );

      expect(entity.avatarUrl, isNull);
    });
  });
}
