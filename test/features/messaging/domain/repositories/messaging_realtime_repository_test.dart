import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_realtime_repository.dart';

class FakeMessagingRealtimeRepository implements MessagingRealtimeRepository {
  final controller = StreamController<RealtimeMessageEventEntity>.broadcast();

  int connectCalls = 0;
  int disconnectCalls = 0;

  @override
  Stream<RealtimeMessageEventEntity> get eventsStream => controller.stream;

  @override
  Future<void> connect() async {
    connectCalls++;
  }

  @override
  Future<void> disconnect() async {
    disconnectCalls++;
  }

  Future<void> dispose() async {
    await controller.close();
  }
}

void main() {
  group('MessagingRealtimeRepository contract', () {
    late FakeMessagingRealtimeRepository repository;

    setUp(() {
      repository = FakeMessagingRealtimeRepository();
    });

    tearDown(() async {
      await repository.dispose();
    });

    test('connect and disconnect are exposed', () async {
      await repository.connect();
      await repository.disconnect();

      expect(repository.connectCalls, 1);
      expect(repository.disconnectCalls, 1);
    });

    test('eventsStream emits realtime events', () async {
      const event = RealtimeMessageEventEntity(
        type: RealtimeMessageEventType.newMessage,
        conversationId: 'conversation-1',
      );

      expectLater(repository.eventsStream, emits(event));

      repository.controller.add(event);
    });
  });
}
