import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_or_create_direct_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/start_direct_conversation_cubit.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/message_user_button.dart';

class MockGetOrCreateDirectConversationUseCase extends Mock
    implements GetOrCreateDirectConversationUseCase {}

void main() {
  final getIt = GetIt.I;

  late MockGetOrCreateDirectConversationUseCase useCase;

  const participant = ParticipantEntity(
    id: 'user-1',
    displayName: 'Listener One',
    handle: 'listener',
    avatarUrl: null,
  );

  const conversation = ConversationEntity(
    conversationId: 'conversation-1',
    participant: participant,
    lastMessage: null,
    unreadCount: 0,
  );

  setUp(() async {
    await getIt.reset();
    useCase = MockGetOrCreateDirectConversationUseCase();

    getIt.registerFactory<StartDirectConversationCubit>(
      () => StartDirectConversationCubit(
        getOrCreateDirectConversationUseCase: useCase,
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpButton(
    WidgetTester tester, {
    bool enabled = true,
  }) {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) {
            return Scaffold(
              body: MessageUserButton(
                receiverId: 'receiver-1',
                enabled: enabled,
              ),
            );
          },
        ),
        GoRoute(
          path: '/messages/:conversationId',
          builder: (context, state) {
            return Scaffold(
              body: Text(
                state.pathParameters['conversationId'] ?? '',
              ),
            );
          },
        ),
      ],
    );

    return tester.pumpWidget(
      MaterialApp.router(routerConfig: router),
    );
  }

  testWidgets('renders message button', (tester) async {
    await pumpButton(tester);

    expect(find.text('Message'), findsOneWidget);
    expect(find.byIcon(Icons.forum_outlined), findsOneWidget);
  });

  testWidgets('starts direct conversation and navigates when tapped',
      (tester) async {
    when(
      () => useCase(receiverId: any(named: 'receiverId')),
    ).thenAnswer((_) async => conversation);

    await pumpButton(tester);

    await tester.tap(find.text('Message'));
    await tester.pumpAndSettle();

    verify(
      () => useCase(receiverId: 'receiver-1'),
    ).called(1);

    expect(find.text('conversation-1'), findsOneWidget);
  });

  testWidgets('does not start direct conversation when disabled',
      (tester) async {
    await pumpButton(tester, enabled: false);

    await tester.tap(find.text('Message'));
    await tester.pump();

    verifyNever(
      () => useCase(receiverId: any(named: 'receiverId')),
    );
  });

  testWidgets('shows loading indicator while starting conversation',
      (tester) async {
    final completer = Completer<ConversationEntity>();

    when(
      () => useCase(receiverId: any(named: 'receiverId')),
    ).thenAnswer((_) => completer.future);

    await pumpButton(tester);

    await tester.tap(find.text('Message'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(conversation);
    await tester.pumpAndSettle();

    expect(find.text('conversation-1'), findsOneWidget);
  });
}
