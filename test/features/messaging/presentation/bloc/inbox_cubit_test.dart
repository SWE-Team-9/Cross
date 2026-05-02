import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/archive_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversations_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_unread_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/unarchive_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/inbox_cubit.dart';

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
  group('InboxCubit', () {
    late MockGetConversationsUseCase getConversationsUseCase;
    late MockMarkConversationReadUseCase markConversationReadUseCase;
    late MockMarkConversationUnreadUseCase markConversationUnreadUseCase;
    late MockArchiveConversationUseCase archiveConversationUseCase;
    late MockUnarchiveConversationUseCase unarchiveConversationUseCase;
    late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;
    late StreamController<RealtimeMessageEventEntity> socketController;
    late InboxCubit cubit;

    const participant = ParticipantEntity(
      id: 'user-1',
      displayName: 'Listener One',
      handle: '@listener',
      avatarUrl: null,
    );

    ConversationEntity conversation(
      String id, {
      int unreadCount = 0,
      bool isArchived = false,
    }) {
      return ConversationEntity(
        conversationId: id,
        participant: participant,
        lastMessage: null,
        unreadCount: unreadCount,
        isArchived: isArchived,
      );
    }

    ConversationListPageEntity page({
      List<ConversationEntity>? conversations,
      int page = 1,
      bool hasMore = false,
    }) {
      final list = conversations ?? <ConversationEntity>[conversation('c1')];

      return ConversationListPageEntity(
        conversations: list,
        page: page,
        limit: 20,
        total: list.length,
        hasMore: hasMore,
      );
    }

    setUp(() {
      getConversationsUseCase = MockGetConversationsUseCase();
      markConversationReadUseCase = MockMarkConversationReadUseCase();
      markConversationUnreadUseCase = MockMarkConversationUnreadUseCase();
      archiveConversationUseCase = MockArchiveConversationUseCase();
      unarchiveConversationUseCase = MockUnarchiveConversationUseCase();
      connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
      socketController =
          StreamController<RealtimeMessageEventEntity>.broadcast();

      when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});
      when(() => connectMessagingSocketUseCase.eventsStream)
          .thenAnswer((_) => socketController.stream);

      cubit = InboxCubit(
        getConversationsUseCase: getConversationsUseCase,
        markConversationReadUseCase: markConversationReadUseCase,
        markConversationUnreadUseCase: markConversationUnreadUseCase,
        archiveConversationUseCase: archiveConversationUseCase,
        unarchiveConversationUseCase: unarchiveConversationUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
      );
    });

    tearDown(() async {
      await cubit.close();
      await socketController.close();
    });

    test('loadInitial loads conversations', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer((_) async => page());

      await cubit.loadInitial();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.conversations, hasLength(1));
      expect(cubit.state.errorMessage, isNull);

      verify(
        () => getConversationsUseCase(
          page: 1,
          limit: 20,
          archived: false,
        ),
      ).called(1);
    });

    test('loadInitial supports archived mode', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer(
        (_) async => page(conversations: <ConversationEntity>[
          conversation('archived', isArchived: true),
        ]),
      );

      await cubit.loadInitial(archived: true);

      expect(cubit.state.isArchivedMode, isTrue);

      verify(
        () => getConversationsUseCase(
          page: 1,
          limit: 20,
          archived: true,
        ),
      ).called(1);
    });

    test('loadInitial stores error on failure', () async {
      final exception = Exception('failed');

      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenThrow(exception);

      await cubit.loadInitial();

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, exception.toString());
    });

    test('toggleArchivedMode toggles mode and reloads', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer((_) async => page());

      await cubit.toggleArchivedMode();

      expect(cubit.state.isArchivedMode, isTrue);

      verify(
        () => getConversationsUseCase(
          page: 1,
          limit: 20,
          archived: true,
        ),
      ).called(1);
    });

    test('refresh reloads current archived mode', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer((_) async => page());

      await cubit.loadInitial(archived: true);
      await cubit.refresh();

      verify(
        () => getConversationsUseCase(
          page: 1,
          limit: 20,
          archived: true,
        ),
      ).called(2);

      expect(cubit.state.isRefreshing, isFalse);
    });

    test('loadMore appends conversations', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer((invocation) async {
        final requestedPage = invocation.namedArguments[#page] as int;
        return page(
          conversations: <ConversationEntity>[
            conversation('c$requestedPage'),
          ],
          page: requestedPage,
          hasMore: requestedPage < 2,
        );
      });

      await cubit.loadInitial();
      await cubit.loadMore();

      expect(
        cubit.state.conversations.map((e) => e.conversationId),
        ['c1', 'c2'],
      );

      verify(
        () => getConversationsUseCase(
          page: 2,
          limit: 20,
          archived: false,
        ),
      ).called(1);
    });

    test('markConversationAsRead sets unreadCount to zero', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer(
        (_) async => page(
          conversations: <ConversationEntity>[
            conversation('c1', unreadCount: 5),
          ],
        ),
      );

      when(
        () => markConversationReadUseCase(any()),
      ).thenAnswer((_) async {});

      await cubit.loadInitial();
      await cubit.markConversationAsRead('c1');

      expect(cubit.state.conversations.single.unreadCount, 0);
      verify(() => markConversationReadUseCase('c1')).called(1);
    });

    test('markConversationAsUnread sets unreadCount to one', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer(
        (_) async => page(
          conversations: <ConversationEntity>[
            conversation('c1', unreadCount: 0),
          ],
        ),
      );

      when(
        () => markConversationUnreadUseCase(any()),
      ).thenAnswer((_) async {});

      await cubit.loadInitial();
      await cubit.markConversationAsUnread('c1');

      expect(cubit.state.conversations.single.unreadCount, 1);
      verify(() => markConversationUnreadUseCase('c1')).called(1);
    });

    test('archiveConversation removes conversation from current list',
        () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer(
        (_) async => page(
          conversations: <ConversationEntity>[
            conversation('c1'),
            conversation('c2'),
          ],
        ),
      );

      when(
        () => archiveConversationUseCase(any()),
      ).thenAnswer((_) async {});

      await cubit.loadInitial();
      await cubit.archiveConversation('c1');

      expect(cubit.state.conversations.map((e) => e.conversationId), ['c2']);
      verify(() => archiveConversationUseCase('c1')).called(1);
    });

    test('unarchiveConversation removes conversation from current list',
        () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer(
        (_) async => page(
          conversations: <ConversationEntity>[
            conversation('c1', isArchived: true),
            conversation('c2', isArchived: true),
          ],
        ),
      );

      when(
        () => unarchiveConversationUseCase(any()),
      ).thenAnswer((_) async {});

      await cubit.loadInitial(archived: true);
      await cubit.unarchiveConversation('c1');

      expect(cubit.state.conversations.map((e) => e.conversationId), ['c2']);
      verify(() => unarchiveConversationUseCase('c1')).called(1);
    });

    test('upsertConversation replaces existing conversation', () async {
      when(
        () => getConversationsUseCase(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer(
        (_) async => page(
          conversations: <ConversationEntity>[conversation('c1')],
        ),
      );

      await cubit.loadInitial();

      cubit.upsertConversation(conversation('c1', unreadCount: 9));

      expect(cubit.state.conversations.single.unreadCount, 9);
    });

    test('upsertConversation inserts matching archived mode conversation',
        () async {
      cubit.upsertConversation(conversation('c1', isArchived: false));

      expect(cubit.state.conversations.single.conversationId, 'c1');
    });

    test('upsertConversation ignores non-matching archived mode conversation',
        () async {
      cubit.upsertConversation(conversation('c1', isArchived: true));

      expect(cubit.state.conversations, isEmpty);
    });
  });
}
