import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/data/datasources/messaging_remote_data_source.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/conversation_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/conversation_list_page_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/conversation_messages_page_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/message_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/participant_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/dto/unread_count_dto.dart';
import 'package:soundcloud_clone/features/messaging/data/repositories/messaging_repository_impl.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';

class MockMessagingRemoteDataSource extends Mock
    implements MessagingRemoteDataSource {}

void main() {
  late MockMessagingRemoteDataSource remoteDataSource;
  late MessagingRepositoryImpl repository;

  const participantDto = ParticipantDto(
    id: 'user-1',
    displayName: 'Listener One',
    handle: '@listener',
    avatarUrl: 'https://example.com/avatar.png',
  );

  final createdAt = DateTime.utc(2026, 4, 30, 10);

  late MessageDto messageDto;
  late ConversationDto conversationDto;
  late ConversationListPageDto conversationListPageDto;
  late ConversationMessagesPageDto conversationMessagesPageDto;

  setUp(() {
    remoteDataSource = MockMessagingRemoteDataSource();
    repository = MessagingRepositoryImpl(remoteDataSource);

    messageDto = MessageDto(
      id: 'message-1',
      conversationId: 'conversation-1',
      senderId: 'sender-1',
      receiverId: 'receiver-1',
      type: MessageType.text,
      text: 'Hello',
      isRead: false,
      createdAt: createdAt,
    );

    conversationDto = ConversationDto(
      conversationId: 'conversation-1',
      participant: participantDto,
      lastMessage: messageDto,
      unreadCount: 2,
      updatedAt: createdAt,
      isArchived: false,
      isBlockedByMe: false,
      hasBlockedMe: false,
      canMessage: true,
      blockReason: null,
    );

    conversationListPageDto = ConversationListPageDto(
      conversations: <ConversationDto>[conversationDto],
      page: 1,
      limit: 20,
      total: 1,
      hasMore: false,
    );

    conversationMessagesPageDto = ConversationMessagesPageDto(
      conversationId: 'conversation-1',
      page: 1,
      limit: 50,
      messages: <MessageDto>[messageDto],
    );
  });

  group('getMyConversations', () {
    test('delegates to datasource with default values and maps dto to entity',
        () async {
      when(
        () => remoteDataSource.getMyConversations(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer((_) async => conversationListPageDto);

      final result = await repository.getMyConversations();

      expect(result.conversations, hasLength(1));
      expect(result.conversations.single.conversationId, 'conversation-1');
      expect(result.page, 1);
      expect(result.limit, 20);
      expect(result.total, 1);
      expect(result.hasMore, isFalse);

      verify(
        () => remoteDataSource.getMyConversations(
          page: 1,
          limit: 20,
          archived: false,
        ),
      ).called(1);
    });

    test('passes custom pagination and archived values', () async {
      when(
        () => remoteDataSource.getMyConversations(
          page: any(named: 'page'),
          limit: any(named: 'limit'),
          archived: any(named: 'archived'),
        ),
      ).thenAnswer((_) async => conversationListPageDto);

      await repository.getMyConversations(
        page: 3,
        limit: 10,
        archived: true,
      );

      verify(
        () => remoteDataSource.getMyConversations(
          page: 3,
          limit: 10,
          archived: true,
        ),
      ).called(1);
    });
  });

  group('getConversationMessages', () {
    test('delegates to datasource with default values and maps dto to entity',
        () async {
      when(
        () => remoteDataSource.getConversationMessages(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => conversationMessagesPageDto);

      final result = await repository.getConversationMessages('conversation-1');

      expect(result.conversationId, 'conversation-1');
      expect(result.page, 1);
      expect(result.limit, 50);
      expect(result.messages, hasLength(1));
      expect(result.messages.single.id, 'message-1');

      verify(
        () => remoteDataSource.getConversationMessages(
          'conversation-1',
          page: 1,
          limit: 50,
        ),
      ).called(1);
    });

    test('passes custom pagination', () async {
      when(
        () => remoteDataSource.getConversationMessages(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => conversationMessagesPageDto);

      await repository.getConversationMessages(
        'conversation-1',
        page: 2,
        limit: 25,
      );

      verify(
        () => remoteDataSource.getConversationMessages(
          'conversation-1',
          page: 2,
          limit: 25,
        ),
      ).called(1);
    });
  });

  test('getConversationMeta delegates and maps dto to entity', () async {
    when(
      () => remoteDataSource.getConversationMeta(any()),
    ).thenAnswer((_) async => conversationDto);

    final result = await repository.getConversationMeta('conversation-1');

    expect(result.conversationId, 'conversation-1');
    expect(result.participant.id, 'user-1');
    expect(result.lastMessage?.id, 'message-1');

    verify(
      () => remoteDataSource.getConversationMeta('conversation-1'),
    ).called(1);
  });

  test('getOrCreateDirectConversation delegates and maps dto to entity',
      () async {
    when(
      () => remoteDataSource.getOrCreateDirectConversation(
        receiverId: any(named: 'receiverId'),
      ),
    ).thenAnswer((_) async => conversationDto);

    final result = await repository.getOrCreateDirectConversation(
      receiverId: 'receiver-1',
    );

    expect(result.conversationId, 'conversation-1');

    verify(
      () => remoteDataSource.getOrCreateDirectConversation(
        receiverId: 'receiver-1',
      ),
    ).called(1);
  });

  test('sendTextMessage delegates and maps dto to entity', () async {
    when(
      () => remoteDataSource.sendTextMessage(
        receiverId: any(named: 'receiverId'),
        text: any(named: 'text'),
      ),
    ).thenAnswer((_) async => messageDto);

    final result = await repository.sendTextMessage(
      receiverId: 'receiver-1',
      text: 'Hello',
    );

    expect(result.id, 'message-1');
    expect(result.text, 'Hello');

    verify(
      () => remoteDataSource.sendTextMessage(
        receiverId: 'receiver-1',
        text: 'Hello',
      ),
    ).called(1);
  });

  group('shareTrack', () {
    test('delegates receiverId, trackId, text and maps dto to entity',
        () async {
      when(
        () => remoteDataSource.shareTrack(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => messageDto);

      final result = await repository.shareTrack(
        receiverId: 'receiver-1',
        trackId: 'track-1',
        text: 'Listen',
      );

      expect(result.id, 'message-1');

      verify(
        () => remoteDataSource.shareTrack(
          receiverId: 'receiver-1',
          trackId: 'track-1',
          text: 'Listen',
        ),
      ).called(1);
    });

    test('passes null text', () async {
      when(
        () => remoteDataSource.shareTrack(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => messageDto);

      await repository.shareTrack(
        receiverId: 'receiver-1',
        trackId: 'track-1',
      );

      verify(
        () => remoteDataSource.shareTrack(
          receiverId: 'receiver-1',
          trackId: 'track-1',
          text: null,
        ),
      ).called(1);
    });
  });

  group('sharePlaylist', () {
    test('delegates receiverId, playlistId, text and maps dto to entity',
        () async {
      when(
        () => remoteDataSource.sharePlaylist(
          receiverId: any(named: 'receiverId'),
          playlistId: any(named: 'playlistId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => messageDto);

      final result = await repository.sharePlaylist(
        receiverId: 'receiver-1',
        playlistId: 'playlist-1',
        text: 'Playlist',
      );

      expect(result.id, 'message-1');

      verify(
        () => remoteDataSource.sharePlaylist(
          receiverId: 'receiver-1',
          playlistId: 'playlist-1',
          text: 'Playlist',
        ),
      ).called(1);
    });

    test('passes null text', () async {
      when(
        () => remoteDataSource.sharePlaylist(
          receiverId: any(named: 'receiverId'),
          playlistId: any(named: 'playlistId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => messageDto);

      await repository.sharePlaylist(
        receiverId: 'receiver-1',
        playlistId: 'playlist-1',
      );

      verify(
        () => remoteDataSource.sharePlaylist(
          receiverId: 'receiver-1',
          playlistId: 'playlist-1',
          text: null,
        ),
      ).called(1);
    });
  });

  test('getUnreadCount delegates and maps dto to entity', () async {
    const dto = UnreadCountDto(count: 7);

    when(
      () => remoteDataSource.getUnreadCount(),
    ).thenAnswer((_) async => dto);

    final result = await repository.getUnreadCount();

    expect(result.count, 7);

    verify(
      () => remoteDataSource.getUnreadCount(),
    ).called(1);
  });

  test('markConversationAsRead delegates to datasource', () async {
    when(
      () => remoteDataSource.markConversationAsRead(any()),
    ).thenAnswer((_) async {});

    await repository.markConversationAsRead('conversation-1');

    verify(
      () => remoteDataSource.markConversationAsRead('conversation-1'),
    ).called(1);
  });

  test('markConversationAsUnread delegates to datasource', () async {
    when(
      () => remoteDataSource.markConversationAsUnread(any()),
    ).thenAnswer((_) async {});

    await repository.markConversationAsUnread('conversation-1');

    verify(
      () => remoteDataSource.markConversationAsUnread('conversation-1'),
    ).called(1);
  });

  test('archiveConversation delegates to datasource', () async {
    when(
      () => remoteDataSource.archiveConversation(any()),
    ).thenAnswer((_) async {});

    await repository.archiveConversation('conversation-1');

    verify(
      () => remoteDataSource.archiveConversation('conversation-1'),
    ).called(1);
  });

  test('unarchiveConversation delegates to datasource', () async {
    when(
      () => remoteDataSource.unarchiveConversation(any()),
    ).thenAnswer((_) async {});

    await repository.unarchiveConversation('conversation-1');

    verify(
      () => remoteDataSource.unarchiveConversation('conversation-1'),
    ).called(1);
  });

  test('deleteConversation delegates to datasource', () async {
    when(
      () => remoteDataSource.deleteConversation(any()),
    ).thenAnswer((_) async {});

    await repository.deleteConversation('conversation-1');

    verify(
      () => remoteDataSource.deleteConversation('conversation-1'),
    ).called(1);
  });

  test('deleteMessage delegates to datasource', () async {
    when(
      () => remoteDataSource.deleteMessage(any()),
    ).thenAnswer((_) async {});

    await repository.deleteMessage('message-1');

    verify(
      () => remoteDataSource.deleteMessage('message-1'),
    ).called(1);
  });

  test('propagates datasource errors', () async {
    final exception = Exception('network failed');

    when(
      () => remoteDataSource.getUnreadCount(),
    ).thenThrow(exception);

    expect(
      () => repository.getUnreadCount(),
      throwsA(same(exception)),
    );
  });
}
