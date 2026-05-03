import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_conversation_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/delete_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_conversation_messages_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/mark_conversation_read_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/send_text_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_playlist_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/share_track_message_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/chat_thread_cubit.dart';

class MockGetConversationMessagesUseCase extends Mock
    implements GetConversationMessagesUseCase {}

class MockSendTextMessageUseCase extends Mock
    implements SendTextMessageUseCase {}

class MockMarkConversationReadUseCase extends Mock
    implements MarkConversationReadUseCase {}

class MockDeleteMessageUseCase extends Mock implements DeleteMessageUseCase {}

class MockDeleteConversationUseCase extends Mock
  implements DeleteConversationUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

class MockShareTrackMessageUseCase extends Mock
    implements ShareTrackMessageUseCase {}

class MockSharePlaylistMessageUseCase extends Mock
    implements SharePlaylistMessageUseCase {}

void main() {
  group('ChatThreadCubit', () {
    late MockGetConversationMessagesUseCase getConversationMessagesUseCase;
    late MockSendTextMessageUseCase sendTextMessageUseCase;
    late MockMarkConversationReadUseCase markConversationReadUseCase;
    late MockDeleteMessageUseCase deleteMessageUseCase;
    late MockDeleteConversationUseCase deleteConversationUseCase;
    late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;
    late MockShareTrackMessageUseCase shareTrackMessageUseCase;
    late MockSharePlaylistMessageUseCase sharePlaylistMessageUseCase;
    late StreamController<RealtimeMessageEventEntity> socketController;
    late ChatThreadCubit cubit;

    MessageEntity message(
      String id, {
      DateTime? createdAt,
      String conversationId = 'conversation-1',
      String? senderId,
      String? text,
    }) {
      return MessageEntity(
        id: id,
        conversationId: conversationId,
        senderId: senderId ?? 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.text,
        text: text ?? 'Hello $id',
        isRead: false,
        createdAt: createdAt ?? DateTime.utc(2026, 4, 30),
        sharedTrack: null,
        sharedPlaylist: null,
      );
    }

    ConversationMessagesPageEntity page({
      List<MessageEntity>? messages,
      int pageNumber = 1,
      int limit = 50,
    }) {
      return ConversationMessagesPageEntity(
        conversationId: 'conversation-1',
        page: pageNumber,
        limit: limit,
        messages: messages ?? <MessageEntity>[message('message-1')],
      );
    }

    setUp(() {
      getConversationMessagesUseCase = MockGetConversationMessagesUseCase();
      sendTextMessageUseCase = MockSendTextMessageUseCase();
      markConversationReadUseCase = MockMarkConversationReadUseCase();
      deleteMessageUseCase = MockDeleteMessageUseCase();
      deleteConversationUseCase = MockDeleteConversationUseCase();
      connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
      shareTrackMessageUseCase = MockShareTrackMessageUseCase();
      sharePlaylistMessageUseCase = MockSharePlaylistMessageUseCase();
      socketController =
          StreamController<RealtimeMessageEventEntity>.broadcast();

      when(
        () => markConversationReadUseCase(any()),
      ).thenAnswer((_) async {});

      when(
        () => connectMessagingSocketUseCase(),
      ).thenAnswer((_) async {});

      when(
        () => connectMessagingSocketUseCase.eventsStream,
      ).thenAnswer((_) => socketController.stream);

      cubit = ChatThreadCubit(
        getConversationMessagesUseCase: getConversationMessagesUseCase,
        sendTextMessageUseCase: sendTextMessageUseCase,
        markConversationReadUseCase: markConversationReadUseCase,
        deleteConversationUseCase: deleteConversationUseCase,
        deleteMessageUseCase: deleteMessageUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
        shareTrackMessageUseCase: shareTrackMessageUseCase,
        sharePlaylistMessageUseCase: sharePlaylistMessageUseCase,
      );
    });

    tearDown(() async {
      await cubit.close();
      await socketController.close();
    });

    test('load stores loaded messages and connects socket', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => page(
          messages: <MessageEntity>[
            message('later', createdAt: DateTime.utc(2026, 4, 30, 12)),
            message('earlier', createdAt: DateTime.utc(2026, 4, 30, 10)),
          ],
        ),
      );

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.messages.map((m) => m.id), ['earlier', 'later']);
      expect(cubit.state.isSocketConnected, isTrue);

      verify(
        () => getConversationMessagesUseCase(
          'conversation-1',
          page: 1,
          limit: 50,
        ),
      ).called(1);
      verify(() => markConversationReadUseCase('conversation-1')).called(1);
      verify(() => connectMessagingSocketUseCase()).called(1);
    });

    test('load emits error on failure', () async {
      final exception = Exception('load failed');

      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenThrow(exception);

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.errorMessage, exception.toString());
    });

    test('loadMore appends and sorts messages when more messages exist',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final requestedPage = invocation.namedArguments[#page] as int;

        if (requestedPage == 1) {
          return page(
            pageNumber: 1,
            limit: 1,
            messages: <MessageEntity>[
              message('message-1', createdAt: DateTime.utc(2026, 4, 30, 12)),
            ],
          );
        }

        return page(
          pageNumber: 2,
          limit: 50,
          messages: <MessageEntity>[
            message('message-2', createdAt: DateTime.utc(2026, 4, 30, 10)),
          ],
        );
      });

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.loadMore();

      expect(cubit.state.messages.map((m) => m.id), [
        'message-2',
        'message-1',
      ]);
      expect(cubit.state.page, 2);
      expect(cubit.state.hasMore, isFalse);

      verify(
        () => getConversationMessagesUseCase(
          'conversation-1',
          page: 2,
          limit: 50,
        ),
      ).called(1);
    });

    test('loadMore returns early before a conversation is loaded', () async {
      await cubit.loadMore();

      verifyNever(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      );
    });

    test('loadMore emits error on failure', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((invocation) async {
        final requestedPage = invocation.namedArguments[#page] as int;
        if (requestedPage == 1) {
          return page(
            pageNumber: 1,
            limit: 1,
            messages: <MessageEntity>[message('message-1')],
          );
        }
        throw Exception('load more failed');
      });

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.loadMore();

      expect(cubit.state.isLoadingMore, isFalse);
      expect(cubit.state.errorMessage, contains('load more failed'));
      expect(cubit.state.messages.single.id, 'message-1');
    });

    test('sendText trims text, sends message, and appends result', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));

      when(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer(
        (_) async => message(
          'sent',
          createdAt: DateTime.utc(2026, 4, 30, 10),
        ),
      );

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.sendText('  Hello  ');

      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.messages.single.id, 'sent');

      verify(
        () => sendTextMessageUseCase(
          receiverId: 'receiver-1',
          text: 'Hello',
        ),
      ).called(1);
    });

    test('sendText adds optimistic message before API completes', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));

      final completer = Completer<MessageEntity>();
      when(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) => completer.future);

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        currentUserId: 'sender-1',
      );

      final sendFuture = cubit.sendText('  Hello now  ');
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSending, isTrue);
      expect(cubit.state.messages.single.id, startsWith('local-'));
      expect(cubit.state.messages.single.text, 'Hello now');
      expect(cubit.state.messages.single.senderId, 'sender-1');

      completer.complete(
        message(
          'sent',
          createdAt: DateTime.utc(2026, 4, 30, 10),
        ).copyWith(text: 'Hello now'),
      );
      await sendFuture;

      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.messages.single.id, 'sent');
    });

    test('sendText keeps optimistic content when API response is sparse',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));

      when(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer(
        (_) async => MessageEntity(
          id: '',
          conversationId: '',
          senderId: null,
          receiverId: null,
          type: MessageType.unknown,
          text: null,
          isRead: false,
          createdAt: DateTime.fromMillisecondsSinceEpoch(0),
          sharedTrack: null,
          sharedPlaylist: null,
        ),
      );

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        currentUserId: 'sender-1',
      );

      await cubit.sendText('Hello stable');

      expect(cubit.state.messages.single.id, startsWith('local-'));
      expect(cubit.state.messages.single.text, 'Hello stable');
      expect(cubit.state.messages.single.createdAt.year, greaterThan(2000));
      expect(cubit.state.messages.single.isDeleted, isFalse);
    });

    test('sendText rolls back optimistic message on failure', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));

      when(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      ).thenThrow(Exception('send failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        currentUserId: 'sender-1',
      );

      await cubit.sendText('Nope');

      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.messages, isEmpty);
      expect(cubit.state.errorMessage, contains('send failed'));
    });

    test('socket echo replaces matching optimistic message', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));

      final completer = Completer<MessageEntity>();
      when(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) => completer.future);

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        currentUserId: 'sender-1',
      );

      final sendFuture = cubit.sendText('Echo me');
      await Future<void>.delayed(Duration.zero);

      socketController.add(
        RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.newMessage,
          conversationId: 'conversation-1',
          message: message(
            'socket-sent',
            senderId: 'sender-1',
            text: 'Echo me',
            createdAt: DateTime.now(),
          ),
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.messages, hasLength(1));
      expect(cubit.state.messages.single.id, 'socket-sent');

      completer.complete(
        message(
          'socket-sent',
          senderId: 'sender-1',
          text: 'Echo me',
          createdAt: DateTime.now(),
        ),
      );
      await sendFuture;

      expect(cubit.state.messages, hasLength(1));
      expect(cubit.state.messages.single.id, 'socket-sent');
    });

    test('sendText ignores blank text', () async {
      await cubit.sendText('   ');

      verifyNever(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      );
    });

    test('sendText emits cannot message error when canMessage is false',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        canMessage: false,
      );

      await cubit.sendText('Hello');

      expect(cubit.state.errorMessage, 'You cannot message this user.');
    });

    test('sendText returns early when receiver is unknown', () async {
      await cubit.sendText('Hello');

      verifyNever(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      );
    });

    test('shareTrack sends trimmed track id and appends result', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));
      when(
        () => shareTrackMessageUseCase(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => message('shared-track'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.shareTrack(' track-1 ', text: 'listen');

      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.messages.single.id, 'shared-track');
      verify(
        () => shareTrackMessageUseCase(
          receiverId: 'receiver-1',
          trackId: 'track-1',
          text: 'listen',
        ),
      ).called(1);
    });

    test('shareTrack reports unavailable use case', () async {
      final localCubit = ChatThreadCubit(
        getConversationMessagesUseCase: getConversationMessagesUseCase,
        sendTextMessageUseCase: sendTextMessageUseCase,
        markConversationReadUseCase: markConversationReadUseCase,
        deleteConversationUseCase: deleteConversationUseCase,
        deleteMessageUseCase: deleteMessageUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
      );
      addTearDown(localCubit.close);

      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());

      await localCubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await localCubit.shareTrack('track-1');

      expect(
        localCubit.state.errorMessage,
        'Track sharing is not available right now.',
      );
    });

    test('shareTrack handles blank ids, blocked state, and failure', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));
      when(
        () => shareTrackMessageUseCase(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      ).thenThrow(Exception('share failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.shareTrack('   ');
      verifyNever(
        () => shareTrackMessageUseCase(
          receiverId: any(named: 'receiverId'),
          trackId: any(named: 'trackId'),
          text: any(named: 'text'),
        ),
      );

      await cubit.shareTrack('track-1');
      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.errorMessage, contains('share failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        canMessage: false,
      );
      await cubit.shareTrack('track-1');

      expect(cubit.state.errorMessage, 'You cannot message this user.');
    });

    test('sharePlaylist sends trimmed playlist id and appends result',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));
      when(
        () => sharePlaylistMessageUseCase(
          receiverId: any(named: 'receiverId'),
          playlistId: any(named: 'playlistId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => message('shared-playlist'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.sharePlaylist(' playlist-1 ', text: 'mix');

      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.messages.single.id, 'shared-playlist');
      verify(
        () => sharePlaylistMessageUseCase(
          receiverId: 'receiver-1',
          playlistId: 'playlist-1',
          text: 'mix',
        ),
      ).called(1);
    });

    test('sharePlaylist reports unavailable use case', () async {
      final localCubit = ChatThreadCubit(
        getConversationMessagesUseCase: getConversationMessagesUseCase,
        sendTextMessageUseCase: sendTextMessageUseCase,
        markConversationReadUseCase: markConversationReadUseCase,
        deleteConversationUseCase: deleteConversationUseCase,
        deleteMessageUseCase: deleteMessageUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
      );
      addTearDown(localCubit.close);

      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());

      await localCubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await localCubit.sharePlaylist('playlist-1');

      expect(
        localCubit.state.errorMessage,
        'Playlist sharing is not available right now.',
      );
    });

    test('sharePlaylist handles blank ids, blocked state, and failure',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));
      when(
        () => sharePlaylistMessageUseCase(
          receiverId: any(named: 'receiverId'),
          playlistId: any(named: 'playlistId'),
          text: any(named: 'text'),
        ),
      ).thenThrow(Exception('playlist share failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.sharePlaylist('   ');
      verifyNever(
        () => sharePlaylistMessageUseCase(
          receiverId: any(named: 'receiverId'),
          playlistId: any(named: 'playlistId'),
          text: any(named: 'text'),
        ),
      );

      await cubit.sharePlaylist('playlist-1');
      expect(cubit.state.isSending, isFalse);
      expect(cubit.state.errorMessage, contains('playlist share failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
        canMessage: false,
      );
      await cubit.sharePlaylist('playlist-1');

      expect(cubit.state.errorMessage, 'You cannot message this user.');
    });

    test('deleteMessage marks message as deleted, then removes placeholder',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => page(
          messages: <MessageEntity>[
            message('message-1'),
            message('message-2'),
          ],
        ),
      );

      when(
        () => deleteMessageUseCase(any()),
      ).thenAnswer((_) async {});

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.deleteMessage('message-1');

      expect(cubit.state.messages, hasLength(2));
      expect(
        cubit.state.messages
            .firstWhere((message) => message.id == 'message-1')
            .isDeleted,
        isTrue,
      );
      verify(() => deleteMessageUseCase('message-1')).called(1);

      await cubit.deleteMessage('message-1');

      expect(cubit.state.messages.map((m) => m.id), ['message-2']);
    });

    test('deleteMessage emits error on failure', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[message('m')]));
      when(() => deleteMessageUseCase(any())).thenThrow(
        Exception('delete failed'),
      );

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.deleteMessage('m');

      expect(cubit.state.messages.single.isDeleted, isFalse);
      expect(cubit.state.errorMessage, contains('delete failed'));
    });

    test('deleteConversation delegates to repository usecase', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));
      when(() => deleteConversationUseCase(any())).thenAnswer((_) async {});

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      await cubit.deleteConversation();

      verify(() => deleteConversationUseCase('message-1')).called(1);
    });

    test('markCurrentConversationAsRead returns early and swallows failures',
        () async {
      await cubit.markCurrentConversationAsRead();
      verifyNever(() => markConversationReadUseCase(any()));

      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());
      when(
        () => markConversationReadUseCase(any()),
      ).thenThrow(Exception('read failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      expect(cubit.state.errorMessage, isNull);
    });

    test('socket newMessage appends matching conversation message', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController.add(
        RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.newMessage,
          conversationId: 'conversation-1',
          message: message('socket-message'),
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.messages.single.id, 'socket-message');
    });

    test('socket newMessage ignores unrelated, null, and duplicate messages',
        () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[message('m')]));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController
        ..add(
          RealtimeMessageEventEntity(
            type: RealtimeMessageEventType.newMessage,
            conversationId: 'other-conversation',
            message: message('ignored', conversationId: 'other-conversation'),
          ),
        )
        ..add(
          const RealtimeMessageEventEntity(
            type: RealtimeMessageEventType.newMessage,
            conversationId: 'conversation-1',
          ),
        )
        ..add(
          RealtimeMessageEventEntity(
            type: RealtimeMessageEventType.newMessage,
            conversationId: 'conversation-1',
            message: message('m'),
          ),
        );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.messages.map((m) => m.id), ['m']);
    });

    test('socket messageDeleted marks matching message as deleted', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer(
        (_) async => page(
          messages: <MessageEntity>[
            message('message-1'),
            message('message-2'),
          ],
        ),
      );

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController.add(
        const RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.messageDeleted,
          conversationId: 'conversation-1',
          messageId: 'message-1',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      final deleted = cubit.state.messages.firstWhere(
        (message) => message.id == 'message-1',
      );
      expect(deleted.isDeleted, isTrue);
    });

    test('socket messageDeleted ignores an empty id', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[message('m')]));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController.add(
        const RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.messageDeleted,
          conversationId: 'conversation-1',
          messageId: '',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.messages.single.isDeleted, isFalse);
    });

    test('socket userBlocked disables sending and emits error', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController.add(
        const RealtimeMessageEventEntity(
          type: RealtimeMessageEventType.userBlocked,
          conversationId: 'conversation-1',
          blockReason: 'Blocked',
        ),
      );

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.errorMessage, 'Blocked');

      await cubit.sendText('Hello');

      verifyNever(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      );
    });

    test('socket userUnblocked re-enables sending', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page(messages: <MessageEntity>[]));
      when(
        () => sendTextMessageUseCase(
          receiverId: any(named: 'receiverId'),
          text: any(named: 'text'),
        ),
      ).thenAnswer((_) async => message('sent'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController
        ..add(
          const RealtimeMessageEventEntity(
            type: RealtimeMessageEventType.userBlocked,
            conversationId: 'conversation-1',
          ),
        )
        ..add(
          const RealtimeMessageEventEntity(
            type: RealtimeMessageEventType.userUnblocked,
            conversationId: 'conversation-1',
          ),
        );
      await Future<void>.delayed(Duration.zero);

      await cubit.sendText('Hello again');

      expect(cubit.state.errorMessage, isNull);
      expect(cubit.state.messages.single.id, 'sent');
    });

    test('socket status and errors update connection state', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      socketController
        ..add(
          const RealtimeMessageEventEntity(
            type: RealtimeMessageEventType.unknown,
            conversationId: 'conversation-1',
          ),
        )
        ..addError(Exception('socket failed'));

      await Future<void>.delayed(Duration.zero);

      expect(cubit.state.isSocketConnected, isFalse);
      expect(cubit.state.errorMessage, contains('socket failed'));
    });

    test('load records socket connection failures', () async {
      when(
        () => getConversationMessagesUseCase(
          any(),
          page: any(named: 'page'),
          limit: any(named: 'limit'),
        ),
      ).thenAnswer((_) async => page());
      when(
        () => connectMessagingSocketUseCase(),
      ).thenThrow(Exception('connect failed'));

      await cubit.load(
        conversationId: 'conversation-1',
        receiverId: 'receiver-1',
      );

      expect(cubit.state.isSocketConnected, isFalse);
      expect(cubit.state.errorMessage, contains('connect failed'));
    });
  });
}
