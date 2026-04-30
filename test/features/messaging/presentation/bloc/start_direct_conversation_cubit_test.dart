import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/start_direct_conversation_cubit.dart';

class MockGetOrCreateDirectConversationUseCase extends Mock
    implements GetOrCreateDirectConversationUseCase {}

void main() {
  group('StartDirectConversationCubit', () {
    late MockGetOrCreateDirectConversationUseCase useCase;
    late StartDirectConversationCubit cubit;

    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: '@listener',
      avatarUrl: null,
    );

    const conversation = ConversationEntity(
      conversationId: 'conversation-1',
      participant: participant,
      lastMessage: null,
      unreadCount: 0,
    );

    setUp(() {
      useCase = MockGetOrCreateDirectConversationUseCase();
      cubit = StartDirectConversationCubit(
        getOrCreateDirectConversationUseCase: useCase,
      );
    });

    tearDown(() async {
      await cubit.close();
    });

    test('initial state is StartDirectConversationState.initial', () {
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.conversation, isNull);
    });

    test('start stores conversation on success', () async {
      when(
        () => useCase(receiverId: any(named: 'receiverId')),
      ).thenAnswer((_) async => conversation);

      await cubit.start(receiverId: 'user-1');

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.conversation, conversation);
      expect(cubit.state.errorMessage, isNull);

      verify(
        () => useCase(receiverId: 'user-1'),
      ).called(1);
    });

    test('start stores error on failure', () async {
      final exception = Exception('failed');

      when(
        () => useCase(receiverId: any(named: 'receiverId')),
      ).thenThrow(exception);

      await cubit.start(receiverId: 'user-1');

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.conversation, isNull);
      expect(cubit.state.errorMessage, exception.toString());
    });

    test('start returns early when already loading', () async {
      final completer = Completer<ConversationEntity>();

      when(
        () => useCase(receiverId: any(named: 'receiverId')),
      ).thenAnswer((_) => completer.future);

      unawaited(cubit.start(receiverId: 'user-1'));
      await Future<void>.delayed(Duration.zero);

      await cubit.start(receiverId: 'user-1');

      verify(
        () => useCase(receiverId: 'user-1'),
      ).called(1);

      completer.complete(conversation);
      await Future<void>.delayed(Duration.zero);
    });
  });
}
