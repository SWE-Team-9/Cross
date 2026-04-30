import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';

void main() {
  group('UnreadCountEntity', () {
    test('stores count', () {
      const entity = UnreadCountEntity(count: 9);

      expect(entity.count, 9);
    });

    test('allows zero count', () {
      const entity = UnreadCountEntity(count: 0);

      expect(entity.count, 0);
    });
  });
}
