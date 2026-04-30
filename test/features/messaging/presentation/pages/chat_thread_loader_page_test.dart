import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_messages_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_meta_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/send_text_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/pages/chat_thread_loader_page.dart';

class MockGetConversationMetaUseCase extends Mock
    implements GetConversationMetaUseCase {}

class MockGetConversationMessagesUseCase extends Mock
    implements GetConversationMessagesUseCase {}

class MockSendTextMessageUseCase extends Mock
    implements SendTextMessageUseCase {}

class MockMarkConversationReadUseCase extends Mock
    implements MarkConversationReadUseCase {}

class MockDeleteMessageUseCase extends Mock implements DeleteMessageUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

void main() {
  final getIt = GetIt.I;

  late MockGetConversationMetaUseCase getConversationMetaUseCase;
  late MockGetConversationMessagesUseCase getConversationMessagesUseCase;
  late MockSendTextMessageUseCase sendTextMessageUseCase;
  late MockMarkConversationReadUseCase markConversationReadUseCase;
  late MockDeleteMessageUseCase deleteMessageUseCase;
  late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  const participant = ParticipantEntity(
    id: 'receiver-1',
    displayName: 'Listener One',
    handle: 'listener',
    avatarUrl: null,
  );

  const conversation = ConversationEntity(
    conversationId: 'conversation-1',
    participant: participant,
    lastMessage: null,
    unreadCount: 0,
    canMessage: false,
    blockReason: 'Blocked',
  );

  setUp(() async {
    await getIt.reset();

    getConversationMetaUseCase = MockGetConversationMetaUseCase();
    getConversationMessagesUseCase = MockGetConversationMessagesUseCase();
    sendTextMessageUseCase = MockSendTextMessageUseCase();
    markConversationReadUseCase = MockMarkConversationReadUseCase();
    deleteMessageUseCase = MockDeleteMessageUseCase();
    connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();

    getIt.registerSingleton<GetConversationMetaUseCase>(
      getConversationMetaUseCase,
    );
    getIt.registerSingleton<GetConversationMessagesUseCase>(
      getConversationMessagesUseCase,
    );
    getIt.registerSingleton<SendTextMessageUseCase>(
      sendTextMessageUseCase,
    );
    getIt.registerSingleton<MarkConversationReadUseCase>(
      markConversationReadUseCase,
    );
    getIt.registerSingleton<DeleteMessageUseCase>(
      deleteMessageUseCase,
    );
    getIt.registerSingleton<ConnectMessagingSocketUseCase>(
      connectMessagingSocketUseCase,
    );

    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenThrow(Exception('not needed'));

    when(
      () => markConversationReadUseCase(any()),
    ).thenAnswer((_) async {});

    when(
      () => connectMessagingSocketUseCase(),
    ).thenAnswer((_) async {});

    when(
      () => connectMessagingSocketUseCase.eventsStream,
    ).thenAnswer((_) => const Stream.empty());
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpPage(WidgetTester tester) {
    return tester.pumpWidget(
      const MaterialApp(
        home: ChatThreadLoaderPage(conversationId: 'conversation-1'),
      ),
    );
  }

  testWidgets('shows loading indicator while loading conversation',
      (tester) async {
    final completer = Completer<ConversationEntity>();

    when(
      () => getConversationMetaUseCase(any()),
    ).thenAnswer((_) => completer.future);

    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(conversation);
    await tester.pump();
  });

  testWidgets('shows error UI when loading conversation fails', (tester) async {
    when(
      () => getConversationMetaUseCase(any()),
    ).thenAnswer(
      (_) => Future<ConversationEntity>.error(Exception('Conversation failed')),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Conversation'), findsOneWidget);
    expect(find.textContaining('Conversation failed'), findsOneWidget);
  });

  testWidgets('opens chat thread page when conversation loads', (tester) async {
    when(
      () => getConversationMetaUseCase(any()),
    ).thenAnswer((_) async => conversation);

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Listener One'), findsOneWidget);
    expect(find.text('@listener'), findsOneWidget);
    expect(find.text('Blocked'), findsOneWidget);
  });
}
