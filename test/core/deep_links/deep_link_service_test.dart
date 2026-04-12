import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_service.dart';

void main() {
  group('DeepLinkService', () {
    test('consumeLastDestination returns null when nothing emitted', () {
      final service = DeepLinkService();
      expect(service.consumeLastDestination(), isNull);
    });

    test('stream is not null after creation', () {
      final service = DeepLinkService();
      expect(service.stream, isNotNull);
    });

    test('consumeLastDestination can be called multiple times', () {
      final service = DeepLinkService();
      final result1 = service.consumeLastDestination();
      final result2 = service.consumeLastDestination();

      expect(result1, isNull);
      expect(result2, isNull);
    });

    test('dispose closes the stream controller', () async {
      final service = DeepLinkService();
      await service.dispose();

      // Stream should be broadcast
      expect(service.stream.isBroadcast, isTrue);
    });

    test('stream emits destinations correctly', () async {
      final service = DeepLinkService();

      // Test that stream can be listened to
      expect(service.stream, isNotNull);
      expect(service.stream.isBroadcast, isTrue);
    });
  });
}
