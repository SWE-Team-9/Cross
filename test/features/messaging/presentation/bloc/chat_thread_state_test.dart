import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/message_type.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/chat_thread_state.dart';

void main() {
  group('ChatThreadState', () {
    MessageEntity message(String id) {
      return MessageEntity(
        id: id,
        conversationId: 'conversation-1',
        senderId: 'sender-1',
        receiverId: 'receiver-1',
        type: MessageType.text,
        text: 'Hello',
        isRead: false,
        createdAt: DateTime.utc(2026, 4, 30),
        sharedTrack: null,
        sharedPlaylist: null,
      );
    }

    test('initial has expected defaults', () {
      final state = ChatThreadState.initial();

      expect(state.isLoading, isFalse);
      expect(state.isSending, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.isSocketConnected, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.messages, isEmpty);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);
    });

    test('copyWith keeps existing values when no values are provided', () {
      final original = ChatThreadState(
        isLoading: true,
        isSending: true,
        isLoadingMore: true,
        isSocketConnected: true,
        errorMessage: 'error',
        messages: <MessageEntity>[message('message-1')],
        page: 2,
        hasMore: false,
      );

      final copy = original.copyWith();

      expect(copy.isLoading, original.isLoading);
      expect(copy.isSending, original.isSending);
      expect(copy.isLoadingMore, original.isLoadingMore);
      expect(copy.isSocketConnected, original.isSocketConnected);
      expect(copy.errorMessage, original.errorMessage);
      expect(copy.messages, original.messages);
      expect(copy.page, original.page);
      expect(copy.hasMore, original.hasMore);
    });

    test('copyWith overrides provided values', () {
      final original = ChatThreadState.initial();
      final messages = <MessageEntity>[message('message-1')];

      final copy = original.copyWith(
        isLoading: true,
        isSending: true,
        isLoadingMore: true,
        isSocketConnected: true,
        errorMessage: 'error',
        messages: messages,
        page: 3,
        hasMore: false,
      );

      expect(copy.isLoading, isTrue);
      expect(copy.isSending, isTrue);
      expect(copy.isLoadingMore, isTrue);
      expect(copy.isSocketConnected, isTrue);
      expect(copy.errorMessage, 'error');
      expect(copy.messages, messages);
      expect(copy.page, 3);
      expect(copy.hasMore, isFalse);
    });

    test('copyWith clearError clears errorMessage', () {
      const original = ChatThreadState(
        isLoading: false,
        isSending: false,
        isLoadingMore: false,
        isSocketConnected: false,
        errorMessage: 'error',
        messages: <MessageEntity>[],
        page: 1,
        hasMore: true,
      );

      final copy = original.copyWith(clearError: true);

      expect(copy.errorMessage, isNull);
    });
  });
}
