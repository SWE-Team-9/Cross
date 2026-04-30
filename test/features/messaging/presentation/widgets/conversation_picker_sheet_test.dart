import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversations_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_track_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/share_track_to_conversation_cubit.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/conversation_picker_sheet.dart';

class MockGetConversationsUseCase extends Mock
    implements GetConversationsUseCase {}

class MockShareTrackMessageUseCase extends Mock
    implements ShareTrackMessageUseCase {}

void main() {
  late MockGetConversationsUseCase getConversationsUseCase;
  late MockShareTrackMessageUseCase shareTrackMessageUseCase;
  late ShareTrackToConversationCubit cubit;

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

  MessageEntity message() {
    return MessageEntity(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'user-1',
      type: MessageType.trackShare,
      text: null,
      isRead: false,
      createdAt: DateTime.utc(2026, 4, 30),
      sharedTrack: null,
      sharedPlaylist: null,
    );
  }

  ConversationListPageEntity page({
    List<ConversationEntity>? conversations,
    bool hasMore = false,
  }) {
    final list = conversations ?? const <ConversationEntity>[conversation];

    return ConversationListPageEntity(
      conversations: list,
      page: 1,
      limit: 20,
      total: list.length,
      hasMore: hasMore,
    );
  }

  setUp(() {
    getConversationsUseCase = MockGetConversationsUseCase();
    shareTrackMessageUseCase = MockShareTrackMessageUseCase();

    cubit = ShareTrackToConversationCubit(
      getConversationsUseCase: getConversationsUseCase,
      shareTrackMessageUseCase: shareTrackMessageUseCase,
    );
  });

  tearDown(() async {
    await cubit.close();
  });

  Future<void> pumpSheet(
    WidgetTester tester, {
    required Future<void> Function(ConversationEntity conversation)
        onConversationSelected,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BlocProvider.value(
            value: cubit,
            child: ConversationPickerSheet(
              title: 'Send track to',
              actionLabel: 'Send',
              onConversationSelected: onConversationSelected,
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('loads conversations on init and renders title/list',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    await pumpSheet(
      tester,
      onConversationSelected: (_) async {},
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('Send track to'), findsOneWidget);
    expect(find.text('Listener One'), findsOneWidget);
    expect(find.text('@listener'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);

    verify(
      () => getConversationsUseCase(page: 1, limit: 20),
    ).called(1);
  });

  testWidgets('shows loading indicator while loading initial conversations',
      (tester) async {
    final completer = Completer<ConversationListPageEntity>();

    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpSheet(
      tester,
      onConversationSelected: (_) async {},
    );

    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(page());
    await tester.pump();
  });

  testWidgets('shows empty message when no conversations exist',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer(
      (_) async => page(conversations: const <ConversationEntity>[]),
    );

    await pumpSheet(
      tester,
      onConversationSelected: (_) async {},
    );

    await tester.pump();
    await tester.pump();

    expect(find.text('No conversations yet'), findsOneWidget);
  });

  testWidgets('calls onConversationSelected when conversation is tapped',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    ConversationEntity? selected;

    await pumpSheet(
      tester,
      onConversationSelected: (conversation) async {
        selected = conversation;
      },
    );

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Listener One'));
    await tester.pump();

    expect(selected?.conversationId, 'conversation-1');
  });

  testWidgets('shows selected loading indicator while sharing', (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    final completer = Completer<MessageEntity>();

    when(
      () => shareTrackMessageUseCase(
        receiverId: any(named: 'receiverId'),
        trackId: any(named: 'trackId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) => completer.future);

    await pumpSheet(
      tester,
      onConversationSelected: (conversation) {
        return cubit.shareTrack(
          conversation: conversation,
          trackId: 'track-1',
        );
      },
    );

    await tester.pump();
    await tester.pump();

    await tester.tap(find.text('Listener One'));
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    completer.complete(message());
    await tester.pump();
  });
}
