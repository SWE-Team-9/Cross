import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

void main() {
  group('UnreadCountCubit', () {
    late MockGetUnreadCountUseCase getUnreadCountUseCase;
    late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;
    late StreamController<RealtimeMessageEventEntity> socketController;
    late UnreadCountCubit cubit;

    setUp(() {
      getUnreadCountUseCase = MockGetUnreadCountUseCase();
      connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
      socketController =
          StreamController<RealtimeMessageEventEntity>.broadcast();

      when(
        () => connectMessagingSocketUseCase.eventsStream,
      ).thenAnswer((_) => socketController.stream);

      when(
        () => connectMessagingSocketUseCase(),
      ).thenAnswer((_) async {});

      cubit = UnreadCountCubit(
        getUnreadCountUseCase: getUnreadCountUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
      );
    });

    tearDown(() async {
      await cubit.close();
      await socketController.close();
    });

    test('initial state is UnreadCountState.initial', () {
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.count, 0);
      expect(cubit.state.errorMessage, isNull);
    });

    test('load stores unread count and connects socket', () async {
      when(
        () => getUnreadCountUseCase(),
      ).thenAnswer((_) async => const UnreadCountEntity(count: 7));

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.count, 7);
      expect(cubit.state.errorMessage, isNull);

      verify(() => getUnreadCountUseCase()).called(1);
      verify(() => connectMessagingSocketUseCase()).called(1);
    });

    test('load stores error when count loading fails', () async {
      final exception = Exception('failed');

      when(
        () => getUnreadCountUseCase(),
      ).thenThrow(exception);

      await cubit.load();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, exception.toString());

      verifyNever(() => connectMessagingSocketUseCase());
    });

    test('refresh updates count', () async {
      when(
        () => getUnreadCountUseCase(),
      ).thenAnswer((_) async => const UnreadCountEntity(count: 4));

      await cubit.refresh();

      expect(cubit.state.count, 4);
      expect(cubit.state.isLoading, isFalse);
    });

    test('refresh stores error when usecase fails', () async {
      final exception = Exception('refresh failed');

      when(
        () => getUnreadCountUseCase(),
      ).thenThrow(exception);

      await cubit.refresh();

      expect(cubit.state.errorMessage, exception.toString());
    });

    test('setCount updates count and clamps negative values to zero', () async {
      cubit.setCount(5);
      expect(cubit.state.count, 5);

      cubit.setCount(-10);
      expect(cubit.state.count, 0);
    });

    test('socket event with currentUnreadCount updates count', () async {
      when(
        () => getUnreadCountUseCase(),
      ).thenAnswer((_) async => const UnreadCountEntity(count: 1));

      await cubit.load();

      socketController.add(
        const RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.unreadCountUpdated,
          conversationId: 'conversation-1',
          currentUnreadCount: 9,
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.count, 9);
    });

    test('socket event without count refreshes for count-affecting event',
        () async {
      when(
        () => getUnreadCountUseCase(),
      ).thenAnswer((_) async => const UnreadCountEntity(count: 1));

      await cubit.load();

      when(
        () => getUnreadCountUseCase(),
      ).thenAnswer((_) async => const UnreadCountEntity(count: 8));

      socketController.add(
        const RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.newMessage,
          conversationId: 'conversation-1',
        ),
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.count, 8);
    });

    test('socket connection failure does not block loaded count', () async {
      when(
        () => getUnreadCountUseCase(),
      ).thenAnswer((_) async => const UnreadCountEntity(count: 6));

      when(
        () => connectMessagingSocketUseCase(),
      ).thenThrow(Exception('socket failed'));

      await cubit.load();

      expect(cubit.state.count, 6);
      expect(cubit.state.errorMessage, isNull);
    });
  });
}
