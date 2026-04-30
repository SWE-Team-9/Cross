import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversations_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_track_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/share_track_to_conversation_cubit.dart';
import 'package:soundcloud_clone/features/messaging/presentation/widgets/share_track_to_conversation_sheet.dart';

class MockGetConversationsUseCase extends Mock
    implements GetConversationsUseCase {}

class MockShareTrackMessageUseCase extends Mock
    implements ShareTrackMessageUseCase {}

void main() {
  final getIt = GetIt.I;

  late MockGetConversationsUseCase getConversationsUseCase;
  late MockShareTrackMessageUseCase shareTrackMessageUseCase;

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

  ConversationListPageEntity page() {
    return const ConversationListPageEntity(
      conversations: <ConversationEntity>[conversation],
      page: 1,
      limit: 20,
      total: 1,
      hasMore: false,
    );
  }

  MessageEntity message() {
    return MessageEntity(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'user-1',
      type: MessageType.trackShare,
      text: 'Listen',
      isRead: false,
      createdAt: DateTime.utc(2026, 4, 30),
      sharedTrack: null,
      sharedPlaylist: null,
    );
  }

  setUp(() async {
    await getIt.reset();

    getConversationsUseCase = MockGetConversationsUseCase();
    shareTrackMessageUseCase = MockShareTrackMessageUseCase();

    getIt.registerFactory<ShareTrackToConversationCubit>(
      () => ShareTrackToConversationCubit(
        getConversationsUseCase: getConversationsUseCase,
        shareTrackMessageUseCase: shareTrackMessageUseCase,
      ),
    );
  });

  tearDown(() async {
    await getIt.reset();
  });

  Future<void> pumpHost(WidgetTester tester) {
    return tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    showShareTrackToConversationSheet(
                      context: context,
                      trackId: 'track-1',
                      text: 'Listen',
                    );
                  },
                  child: const Text('Open sheet'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  testWidgets('opens sheet and renders conversations', (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    await pumpHost(tester);

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Send track to'), findsOneWidget);
    expect(find.text('Listener One'), findsOneWidget);
    expect(find.text('Send'), findsOneWidget);
  });

  testWidgets('selecting conversation shares track through cubit',
      (tester) async {
    when(
      () => getConversationsUseCase(
        page: any(named: 'page'),
        limit: any(named: 'limit'),
        archived: any(named: 'archived'),
      ),
    ).thenAnswer((_) async => page());

    when(
      () => shareTrackMessageUseCase(
        receiverId: any(named: 'receiverId'),
        trackId: any(named: 'trackId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) async => message());

    await pumpHost(tester);

    await tester.tap(find.text('Open sheet'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Listener One'));
    await tester.pumpAndSettle();

    verify(
      () => shareTrackMessageUseCase(
        receiverId: 'user-1',
        trackId: 'track-1',
        text: 'Listen',
      ),
    ).called(1);
  });
}
