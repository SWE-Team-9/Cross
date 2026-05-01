import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/repositories/messaging_realtime_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';

class MockMessagingRealtimeRepository extends Mock
    implements MessagingRealtimeRepository {}

void main() {
  late MockMessagingRealtimeRepository repository;
  late ConnectMessagingSocketUseCase useCase;
  late StreamController<RealtimeMessageEventEntity> controller;

  setUp(() {
    repository = MockMessagingRealtimeRepository();
    controller = StreamController<RealtimeMessageEventEntity>.broadcast();
    useCase = ConnectMessagingSocketUseCase(repository);
  });

  tearDown(() async {
    await controller.close();
  });

  test('delegates connect to repository', () async {
    when(repository.connect).thenAnswer((_) async {});

    await useCase();

    verify(repository.connect).called(1);
  });

  test('delegates disconnect to repository', () async {
    when(repository.disconnect).thenAnswer((_) async {});

    await useCase.disconnect();

    verify(repository.disconnect).called(1);
  });

  test('exposes repository eventsStream', () async {
    when(
      () => repository.eventsStream,
    ).thenAnswer((_) => controller.stream);

    const event = RealtimeMessageEventEntity(
      type: RealtimeMessageEventType.newMessage,
      conversationId: 'conversation-1',
    );

    expectLater(useCase.eventsStream, emits(event));

    controller.add(event);
  });

  test('propagates connect errors', () async {
    final exception = Exception('connect failed');

    when(repository.connect).thenThrow(exception);

    expect(
      () => useCase(),
      throwsA(same(exception)),
    );
  });

  test('propagates disconnect errors', () async {
    final exception = Exception('disconnect failed');

    when(repository.disconnect).thenThrow(exception);

    expect(
      () => useCase.disconnect(),
      throwsA(same(exception)),
    );
  });
}
