import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_messages_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/send_text_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_track_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/pages/chat_thread_page.dart';

class MockGetConversationMessagesUseCase extends Mock
    implements GetConversationMessagesUseCase {}

class MockSendTextMessageUseCase extends Mock
    implements SendTextMessageUseCase {}

class MockMarkConversationReadUseCase extends Mock
    implements MarkConversationReadUseCase {}

class MockDeleteMessageUseCase extends Mock implements DeleteMessageUseCase {}

class MockShareTrackMessageUseCase extends Mock
    implements ShareTrackMessageUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

class MockAuthCubit extends Mock implements AuthCubit {}

class MockAuthState extends Mock implements AuthState {}

void main() {
  final getIt = GetIt.I;

  late MockGetConversationMessagesUseCase getConversationMessagesUseCase;
  late MockSendTextMessageUseCase sendTextMessageUseCase;
  late MockMarkConversationReadUseCase markConversationReadUseCase;
  late MockDeleteMessageUseCase deleteMessageUseCase;
  late MockShareTrackMessageUseCase shareTrackMessageUseCase;
  late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;
  late StreamController<RealtimeMessageEventEntity> socketController;
  late MockAuthCubit authCubit;

  MessageEntity message({
    String id = 'message-1',
    String senderId = 'sender-1',
    String text = 'Hello',
    DateTime? createdAt,
  }) {
    return MessageEntity(
      id: id,
      conversationId: 'conversation-1',
      senderId: senderId,
      receiverId: 'receiver-1',
      type: MessageType.text,
      text: text,
      isRead: false,
      createdAt: createdAt ?? DateTime(2026, 4, 30, 10),
      sharedTrack: null,
      sharedPlaylist: null,
    );
  }

  ConversationMessagesPageEntity page({
    List<MessageEntity>? messages,
    bool hasMore = false,
  }) {
    final list = messages ?? <MessageEntity>[message()];

    return ConversationMessagesPageEntity(
      conversationId: 'conversation-1',
      page: 1,
      limit: hasMore ? list.length : 50,
      messages: list,
    );
  }

  setUp(() async {
    await getIt.reset();

    getConversationMessagesUseCase = MockGetConversationMessagesUseCase();
    sendTextMessageUseCase = MockSendTextMessageUseCase();
    markConversationReadUseCase = MockMarkConversationReadUseCase();
    deleteMessageUseCase = MockDeleteMessageUseCase();
    shareTrackMessageUseCase = MockShareTrackMessageUseCase();
    connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
    socketController = StreamController<RealtimeMessageEventEntity>.broadcast();
    authCubit = MockAuthCubit();

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
    getIt.registerSingleton<ShareTrackMessageUseCase>(
      shareTrackMessageUseCase,
    );
    getIt.registerSingleton<ConnectMessagingSocketUseCase>(
      connectMessagingSocketUseCase,
    );

    when(
      () => markConversationReadUseCase(any()),
    ).thenAnswer((_) async {});

    when(
      () => deleteMessageUseCase(any()),
    ).thenAnswer((_) async {});

    when(
      () => shareTrackMessageUseCase(any()),
    ).thenAnswer((_) async => MessageEntity(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'receiver-1',
      type: MessageType.trackShare,
      text: null,
      isRead: false,
      createdAt: DateTime(2026, 4, 30, 10),
      sharedTrack: null,
      sharedPlaylist: null,
    ));

    when(
      () => connectMessagingSocketUseCase(),
    ).thenAnswer((_) async {});

    when(
      () => connectMessagingSocketUseCase.eventsStream,
    ).thenAnswer((_) => socketController.stream);

    when(
      () => authCubit.state,
    ).thenReturn(MockAuthState());

    when(
      () => authCubit.stream,
    ).thenAnswer((_) => const Stream<AuthState>.empty());

    when(
      () => authCubit.close(),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await socketController.close();
    await getIt.reset();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    bool canMessage = true,
    String? blockReason,
    VoidCallback? onBack,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: ChatThreadPage(
            conversationId: 'conversation-1',
            receiverId: 'receiver-1',
            participantDisplayName: 'Listener One',
            participantHandle: 'listener',
            participantAvatarUrl: null,
            canMessage: canMessage,
            blockReason: blockReason,
            onBack: onBack,
          ),
        ),
      ),
    );
  }

  testWidgets('shows loading indicator while messages load', (tester) async {
    final completer = Completer<ConversationMessagesPageEntity>();

    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpPage(tester);

    expect(find.text('Listener One'), findsOneWidget);
    expect(find.text('@listener'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(page());
    await tester.pump();
  });

  testWidgets('renders loaded messages and composer', (tester) async {
    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => page(
        messages: <MessageEntity>[
          message(
            id: 'message-1',
            text: 'First message',
            createdAt: DateTime(2026, 4, 30, 10),
          ),
        ],
      ),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Listener One'), findsOneWidget);
    expect(find.text('@listener'), findsOneWidget);
    expect(find.text('First message'), findsOneWidget);
    expect(find.text('Write a message...'), findsOneWidget);

    verify(
      () => getConversationMessagesUseCase(
        'conversation-1',
        page: 1,
        limit: 50,
      ),
    ).called(1);

    verify(
      () => markConversationReadUseCase('conversation-1'),
    ).called(1);
  });

  testWidgets('shows empty state when there are no messages', (tester) async {
    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => page(messages: <MessageEntity>[]),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Start the conversation'), findsOneWidget);
    expect(find.text('Write a message...'), findsOneWidget);
  });

  testWidgets('shows error state and retry when initial load fails',
      (tester) async {
    var calls = 0;

    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        throw Exception('load failed');
      }
      return page();
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.textContaining('load failed'), findsOneWidget);
    expect(find.text('Retry'), findsOneWidget);

    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();

    expect(find.text('Hello'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('sending a message calls send usecase', (tester) async {
    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => page(messages: <MessageEntity>[]),
    );

    when(
      () => sendTextMessageUseCase(
        receiverId: any(named: 'receiverId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer(
      (_) async => message(
        id: 'sent-message',
        text: 'Hello there',
      ),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), '  Hello there  ');
    await tester.tap(find.byIcon(Icons.send_rounded));
    await tester.pumpAndSettle();

    verify(
      () => sendTextMessageUseCase(
        receiverId: 'receiver-1',
        text: 'Hello there',
      ),
    ).called(1);

    expect(find.text('Hello there'), findsOneWidget);
  });

  testWidgets('blocked conversation shows banner and hides composer',
      (tester) async {
    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => page(messages: <MessageEntity>[]),
    );

    await pumpPage(
      tester,
      canMessage: false,
      blockReason: 'You are blocked',
    );
    await tester.pumpAndSettle();

    expect(find.text('You are blocked'), findsOneWidget);
    expect(find.byIcon(Icons.block), findsOneWidget);
    expect(find.text('Write a message...'), findsNothing);
  });

  testWidgets('back button calls custom onBack when provided', (tester) async {
    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => page(messages: <MessageEntity>[]),
    );

    var backCalled = false;

    await pumpPage(
      tester,
      onBack: () => backCalled = true,
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pump();

    expect(backCalled, isTrue);
  });

  testWidgets('realtime new message appears in thread', (tester) async {
    when(
      () => getConversationMessagesUseCase(
        any(),
        page: any(named: 'page'),
        limit: any(named: 'limit'),
      ),
    ).thenAnswer(
      (_) async => page(messages: <MessageEntity>[]),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    socketController.add(
      RealtimeMessageEventEntity(
        type: RealtimeMessageEventType.newMessage,
        conversationId: 'conversation-1',
        message: message(
          id: 'socket-message',
          text: 'Socket hello',
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Socket hello'), findsOneWidget);
  });
}
