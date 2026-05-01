import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_messages_page_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
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
    late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;
    late MockShareTrackMessageUseCase shareTrackMessageUseCase;
    late MockSharePlaylistMessageUseCase sharePlaylistMessageUseCase;
    late StreamController<RealtimeMessageEventEntity> socketController;
    late ChatThreadCubit cubit;

    MessageEntity message(
      String id, {
      DateTime? createdAt,
      String conversationId = 'conversation-1',
    }) {
      return MessageEntity(
        id: id,
        conversationId: conversationId,
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.text,
        text: 'Hello $id',
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

    test('deleteMessage removes message from state', () async {
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

      expect(cubit.state.messages.map((m) => m.id), ['message-2']);
      verify(() => deleteMessageUseCase('message-1')).called(1);
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

    test('socket messageDeleted removes matching message', () async {
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

      expect(cubit.state.messages.map((m) => m.id), ['message-2']);
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
  });
}
