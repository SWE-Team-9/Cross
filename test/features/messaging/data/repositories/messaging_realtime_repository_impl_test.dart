import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/data/datasources/messaging_socket_data_source.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/socket_message_event_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/repositories/messaging_realtime_repository_impl.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';

class MockMessagingSocketDataSource extends Mock
    implements MessagingSocketDataSource {}

void main() {
  late MockMessagingSocketDataSource socketDataSource;
  late MessagingRealtimeRepositoryImpl repository;
  late StreamController<SocketMessageEventDto> controller;

  setUp(() {
    socketDataSource = MockMessagingSocketDataSource();
    repository = MessagingRealtimeRepositoryImpl(socketDataSource);
    controller = StreamController<SocketMessageEventDto>.broadcast();
  });

  tearDown(() async {
    await controller.close();
  });

  test('eventsStream maps SocketMessageEventDto to entity', () async {
    when(
      () => socketDataSource.eventsStream,
    ).thenAnswer((_) => controller.stream);

    const dto = SocketMessageEventDto(
      type: RealtimeMessageEventType.newMessage,
      conversationId: 'conversation-1',
      messageId: 'message-1',
      currentUnreadCount: 3,
      isBlockedByMe: false,
      hasBlockedMe: false,
      canMessage: true,
      blockReason: null,
    );

    expectLater(
      repository.eventsStream,
      emits(
        isA<RealtimeMessageEventEntity>()
            .having(
              (event) => event.type,
              'type',
              RealtimeMessageEventType.newMessage,
            )
            .having(
              (event) => event.conversationId,
              'conversationId',
              'conversation-1',
            )
            .having(
              (event) => event.messageId,
              'messageId',
              'message-1',
            )
            .having(
              (event) => event.currentUnreadCount,
              'currentUnreadCount',
              3,
            )
            .having(
              (event) => event.canMessage,
              'canMessage',
              true,
            ),
      ),
    );

    controller.add(dto);
  });

  test('eventsStream forwards stream errors', () async {
    when(
      () => socketDataSource.eventsStream,
    ).thenAnswer((_) => controller.stream);

    final exception = Exception('socket failed');

    expectLater(
      repository.eventsStream,
      emitsError(same(exception)),
    );

    controller.addError(exception);
  });

  test('connect delegates to socket datasource', () async {
    when(
      () => socketDataSource.connect(),
    ).thenAnswer((_) async {});

    await repository.connect();

    verify(
      () => socketDataSource.connect(),
    ).called(1);
  });

  test('disconnect delegates to socket datasource', () async {
    when(
      () => socketDataSource.disconnect(),
    ).thenAnswer((_) async {});

    await repository.disconnect();

    verify(
      () => socketDataSource.disconnect(),
    ).called(1);
  });

  test('connect propagates datasource errors', () async {
    final exception = Exception('connect failed');

    when(
      () => socketDataSource.connect(),
    ).thenThrow(exception);

    expect(
      () => repository.connect(),
      throwsA(same(exception)),
    );
  });

  test('disconnect propagates datasource errors', () async {
    final exception = Exception('disconnect failed');

    when(
      () => socketDataSource.disconnect(),
    ).thenThrow(exception);

    expect(
      () => repository.disconnect(),
      throwsA(same(exception)),
    );
  });
}
