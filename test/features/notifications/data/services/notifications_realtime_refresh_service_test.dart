import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/notifications/data/services/notifications_realtime_refresh_service.dart';

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

void main() {
  late MockConnectMessagingSocketUseCase mockUseCase;
  late StreamController<RealtimeMessageEventEntity> controller;
  late NotificationsRealtimeRefreshService service;

  setUp(() {
    mockUseCase = MockConnectMessagingSocketUseCase();
    controller = StreamController<RealtimeMessageEventEntity>.broadcast();
    when(() => mockUseCase()).thenAnswer((_) async {});
    when(() => mockUseCase.eventsStream).thenAnswer((_) => controller.stream);
    service = NotificationsRealtimeRefreshService(mockUseCase);
  });

  tearDown(() async {
    await controller.close();
    await service.dispose();
  });

  RealtimeMessageEventEntity makeEvent(
    RealtimeMessageEventType type, {
    int? currentUnreadCount,
  }) {
    return RealtimeMessageEventEntity(
      type: type,
      conversationId: 'conversation-1',
      currentUnreadCount: currentUnreadCount,
    );
  }

  test('start listens to refresh-triggering events only once', () async {
    final refreshes = <int>[];
    final subscription = service.refreshStream.listen((_) {
      refreshes.add(1);
    });

    await service.start();
    await service.start();

    verify(() => mockUseCase()).called(1);

    controller.add(makeEvent(RealtimeMessageEventType.newMessage));
    controller.add(makeEvent(RealtimeMessageEventType.userBlocked));
    controller.add(
      makeEvent(
        RealtimeMessageEventType.unknown,
        currentUnreadCount: 5,
      ),
    );

    await Future<void>.delayed(Duration.zero);

    expect(refreshes.length, 2);

    await service.stop();
    controller.add(makeEvent(RealtimeMessageEventType.newMessage));
    await Future<void>.delayed(Duration.zero);

    expect(refreshes.length, 2);

    await subscription.cancel();
  });

  test('stop and dispose are safe without a running socket', () async {
    await service.stop();
    await service.dispose();
    expect(service.refreshStream.isBroadcast, isTrue);
  });
}
