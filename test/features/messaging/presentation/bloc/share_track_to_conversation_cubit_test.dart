import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_list_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversations_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_playlist_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_track_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/share_track_to_conversation_cubit.dart';

class MockGetConversationsUseCase extends Mock
    implements GetConversationsUseCase {}

class MockShareTrackMessageUseCase extends Mock
    implements ShareTrackMessageUseCase {}

class MockSharePlaylistMessageUseCase extends Mock
    implements SharePlaylistMessageUseCase {}

void main() {
  group('ShareTrackToConversationCubit', () {
    late MockGetConversationsUseCase getConversationsUseCase;
    late MockShareTrackMessageUseCase shareTrackMessageUseCase;
    late MockSharePlaylistMessageUseCase sharePlaylistMessageUseCase;
    late ShareTrackToConversationCubit cubit;

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

    ConversationListPageEntity page({
      List<ConversationEntity>? conversations,
      int page = 1,
      bool hasMore = false,
    }) {
      final list = conversations ?? const <ConversationEntity>[conversation];

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
      shareTrackMessageUseCase = MockShareTrackMessageUseCase();
      sharePlaylistMessageUseCase = MockSharePlaylistMessageUseCase();

      cubit = ShareTrackToConversationCubit(
        getConversationsUseCase: getConversationsUseCase,
        shareTrackMessageUseCase: shareTrackMessageUseCase,
        sharePlaylistMessageUseCase: sharePlaylistMessageUseCase,
      );
    });

    tearDown(() async {
      await cubit.close();
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

      expect(cubit.state.isLoadingConversations, isFalse);
      expect(cubit.state.conversations, hasLength(1));
      expect(cubit.state.errorMessage, isNull);

      verify(
        () => getConversationsUseCase(page: 1, limit: 20),
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

      expect(cubit.state.isLoadingConversations, isFalse);
      expect(cubit.state.errorMessage, exception.toString());
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
            conversation.copyWith(conversationId: 'c$requestedPage'),
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
        () => getConversationsUseCase(page: 2, limit: 20),
      ).called(1);
    });

    test('shareTrack stores success message', () async {
      when(
        () => shareTrackMessageUseCase(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => message());

      await cubit.shareTrack(
        conversation: conversation,
        trackId: 'track-1',
        text: 'Listen',
      );

      expect(cubit.state.isSharing, isFalse);
      expect(cubit.state.successMessage, 'Track sent to Listener One');
      expect(cubit.state.errorMessage, isNull);

      verify(
        () => shareTrackMessageUseCase(
          receiverId: 'user-1',
          trackId: 'track-1',
          text: 'Listen',
        ),
      ).called(1);
    });

    test('shareTrack stores error on failure', () async {
      final exception = Exception('share failed');

      when(
        () => shareTrackMessageUseCase(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      ).thenThrow(exception);

      await cubit.shareTrack(
        conversation: conversation,
        trackId: 'track-1',
      );

      expect(cubit.state.isSharing, isFalse);
      expect(cubit.state.errorMessage, exception.toString());
    });

    test('sharePlaylist stores success message', () async {
      when(
        () => sharePlaylistMessageUseCase(
          receiverId: any(named: 'receiverId'),
          playlistId: any(named: 'playlistId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => message());

      await cubit.sharePlaylist(
        conversation: conversation,
        playlistId: 'playlist-1',
        text: 'Listen',
      );

      expect(cubit.state.isSharing, isFalse);
      expect(cubit.state.successMessage, 'Playlist sent to Listener One');
      expect(cubit.state.errorMessage, isNull);

      verify(
        () => sharePlaylistMessageUseCase(
          receiverId: 'user-1',
          playlistId: 'playlist-1',
          text: 'Listen',
        ),
      ).called(1);
    });
  });
}
