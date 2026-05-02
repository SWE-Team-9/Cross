import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/archive_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversations_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_unread_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/unarchive_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/pages/inbox_page.dart';

class MockGetConversationsUseCase extends Mock
    implements GetConversationsUseCase {}

class MockMarkConversationReadUseCase extends Mock
    implements MarkConversationReadUseCase {}

class MockMarkConversationUnreadUseCase extends Mock
    implements MarkConversationUnreadUseCase {}

class MockArchiveConversationUseCase extends Mock
    implements ArchiveConversationUseCase {}

class MockUnarchiveConversationUseCase extends Mock
    implements UnarchiveConversationUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

void main() {
  final getIt = GetIt.I;

  late MockGetConversationsUseCase getConversationsUseCase;
  late MockMarkConversationReadUseCase markConversationReadUseCase;
  late MockMarkConversationUnreadUseCase markConversationUnreadUseCase;
  late MockArchiveConversationUseCase archiveConversationUseCase;
  late MockUnarchiveConversationUseCase unarchiveConversationUseCase;
  late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;
  late StreamController<RealtimeMessageEventEntity> socketController;

  const participant = ParticipantEntity(
    id: 'user-1',
    displayName: 'Listener One',
    handle: 'listener',
    avatarUrl: null,
  );

  MessageEntity message({
    String id = 'message-1',
    String text = 'Hello',
  }) {
    return MessageEntity(
      id: id,
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'receiver-1',
      type: MessageType.text,
      text: text,
      isRead: false,
      createdAt: DateTime(2026, 4, 30, 10),
      sharedTrack: null,
      sharedPlaylist: null,
    );
  }

  ConversationEntity conversation({
    String id = 'conversation-1',
    int unreadCount = 0,
    bool isArchived = false,
  }) {
    return ConversationEntity(
      conversationId: id,
      participant: participant,
      lastMessage: message(),
      unreadCount: unreadCount,
      isArchived: isArchived,
    );
  }

  ConversationListPageEntity page({
    List<ConversationEntity>? conversations,
    int page = 1,
    bool hasMore = false,
  }) {
    final list = conversations ?? <ConversationEntity>[conversation()];

    return ConversationListPageEntity(
      conversations: list,
      page: page,
      limit: 20,
      total: list.length,
      hasMore: hasMore,
    );
  }

  setUp(() async {
    await getIt.reset();

    getConversationsUseCase = MockGetConversationsUseCase();
    markConversationReadUseCase = MockMarkConversationReadUseCase();
    markConversationUnreadUseCase = MockMarkConversationUnreadUseCase();
    archiveConversationUseCase = MockArchiveConversationUseCase();
    unarchiveConversationUseCase = MockUnarchiveConversationUseCase();
    connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
    socketController = StreamController<RealtimeMessageEventEntity>.broadcast();

    getIt.registerSingleton<GetConversationsUseCase>(getConversationsUseCase);
    getIt.registerSingleton<MarkConversationReadUseCase>(
      markConversationReadUseCase,
    );
    getIt.registerSingleton<MarkConversationUnreadUseCase>(
      markConversationUnreadUseCase,
    );
    getIt.registerSingleton<ArchiveConversationUseCase>(
      archiveConversationUseCase,
    );
    getIt.registerSingleton<UnarchiveConversationUseCase>(
      unarchiveConversationUseCase,
    );
    getIt.registerSingleton<ConnectMessagingSocketUseCase>(
      connectMessagingSocketUseCase,
    );

    when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});
    when(() => connectMessagingSocketUseCase.eventsStream)
        .thenAnswer((_) => socketController.stream);

    when(
      () => markConversationReadUseCase(any()),
    ).thenAnswer((_) async {});

    when(
      () => markConversationUnreadUseCase(any()),
    ).thenAnswer((_) async {});

    when(
      () => archiveConversationUseCase(any()),
    ).thenAnswer((_) async {});

    when(
      () => unarchiveConversationUseCase(any()),
    ).thenAnswer((_) async {});
  });

  tearDown(() async {
    await getIt.reset();
    await socketController.close();
  });

  Future<void> pumpPage(
    WidgetTester tester, {
    Future<void> Function(ConversationEntity conversation)? onOpenConversation,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: InboxPage(
          onOpenConversation: onOpenConversation ?? (_) async {},
        ),
      ),
    );
  }

  testWidgets('shows loading indicator while conversations load',
      (tester) async {
    final completer = Completer<ConversationListPageEntity>();

    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpPage(tester);

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('Messages'), findsOneWidget);

    completer.complete(page());
    await tester.pump();
  });

  testWidgets('renders loaded conversations', (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Messages'), findsOneWidget);
    expect(find.text('Listener One'), findsOneWidget);
    expect(find.text('@listener'), findsOneWidget);
    expect(find.text('Hello'), findsOneWidget);

    verify(
      () => getConversationsUseCase(
        page: 1,
        limit: 20,
        archived: false,
      ),
    ).called(1);
  });

  testWidgets('shows empty inbox message', (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer(
      (_) async => page(conversations: <ConversationEntity>[]),
    );

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('No conversations yet'), findsOneWidget);
    expect(
      find.text('When you start chatting with someone, it will show up here.'),
      findsOneWidget,
    );
  });

  testWidgets('shows error and retry when initial load fails', (tester) async {
    var calls = 0;

    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
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

    expect(find.text('Listener One'), findsOneWidget);
    expect(calls, 2);
  });

  testWidgets('opening a conversation marks it as read and calls callback',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer(
      (_) async => page(
        conversations: <ConversationEntity>[
          conversation(unreadCount: 5),
        ],
      ),
    );

    ConversationEntity? opened;

    await pumpPage(
      tester,
      onOpenConversation: (conversation) async {
        opened = conversation;
      },
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Listener One'));
    await tester.pumpAndSettle();

    expect(opened?.conversationId, 'conversation-1');

    verify(
      () => markConversationReadUseCase('conversation-1'),
    ).called(1);
  });

  testWidgets('more button opens actions and mark unread works',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Mark as read'), findsOneWidget);
    expect(find.text('Mark as unread'), findsOneWidget);
    expect(find.text('Archive conversation'), findsOneWidget);

    await tester.tap(find.text('Mark as unread'));
    await tester.pumpAndSettle();

    verify(
      () => markConversationUnreadUseCase('conversation-1'),
    ).called(1);
  });

  testWidgets('archive action removes conversation from inbox', (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    await pumpPage(tester);
    await tester.pumpAndSettle();

    expect(find.text('Listener One'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archive conversation'));
    await tester.pumpAndSettle();

    verify(
      () => archiveConversationUseCase('conversation-1'),
    ).called(1);

    expect(find.text('Listener One'), findsNothing);
  });

  testWidgets('toggle archived mode loads archived conversations',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((invocation) async {
      final archived = invocation.namedArguments[#archived] as bool;
      if (archived) {
        return page(
          conversations: <ConversationEntity>[
            conversation(id: 'archived-1', isArchived: true),
          ],
        );
      }
      return page(conversations: <ConversationEntity>[]);
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();

    expect(find.text('Archived Messages'), findsOneWidget);
    expect(find.text('Listener One'), findsOneWidget);

    verify(
      () => getConversationsUseCase(
        page: 1,
        limit: 20,
        archived: true,
      ),
    ).called(1);
  });

  testWidgets('archived mode shows unarchive action', (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((invocation) async {
      final archived = invocation.namedArguments[#archived] as bool;
      return page(
        conversations: archived
            ? <ConversationEntity>[
                conversation(id: 'conversation-1', isArchived: true),
              ]
            : <ConversationEntity>[],
      );
    });

    await pumpPage(tester);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Archived'));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Unarchive conversation'), findsOneWidget);

    await tester.tap(find.text('Unarchive conversation'));
    await tester.pumpAndSettle();

    verify(
      () => unarchiveConversationUseCase('conversation-1'),
    ).called(1);
  });
}
