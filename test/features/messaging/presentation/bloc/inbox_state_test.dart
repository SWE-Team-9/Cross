import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/inbox_state.dart';

void main() {
  group('InboxState', () {
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
      unreadCount: 1,
    );

    test('initial has expected defaults', () {
      final state = InboxState.initial();

      expect(state.isLoading, isFalse);
      expect(state.isRefreshing, isFalse);
      expect(state.isLoadingMore, isFalse);
      expect(state.isArchivedMode, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.conversations, isEmpty);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);
    });

    test('copyWith keeps existing values when no values are provided', () {
      const original = InboxState(
        isLoading: true,
        isRefreshing: true,
        isLoadingMore: true,
        isArchivedMode: true,
        errorMessage: 'error',
        conversations: <ConversationEntity>[conversation],
        page: 2,
        hasMore: false,
      );

      final copy = original.copyWith();

      expect(copy.isLoading, original.isLoading);
      expect(copy.isRefreshing, original.isRefreshing);
      expect(copy.isLoadingMore, original.isLoadingMore);
      expect(copy.isArchivedMode, original.isArchivedMode);
      expect(copy.errorMessage, original.errorMessage);
      expect(copy.conversations, original.conversations);
      expect(copy.page, original.page);
      expect(copy.hasMore, original.hasMore);
    });

    test('copyWith overrides provided values', () {
      final original = InboxState.initial();

      final copy = original.copyWith(
        isLoading: true,
        isRefreshing: true,
        isLoadingMore: true,
        isArchivedMode: true,
        errorMessage: 'error',
        conversations: const <ConversationEntity>[conversation],
        page: 4,
        hasMore: false,
      );

      expect(copy.isLoading, isTrue);
      expect(copy.isRefreshing, isTrue);
      expect(copy.isLoadingMore, isTrue);
      expect(copy.isArchivedMode, isTrue);
      expect(copy.errorMessage, 'error');
      expect(copy.conversations, const <ConversationEntity>[conversation]);
      expect(copy.page, 4);
      expect(copy.hasMore, isFalse);
    });

    test('copyWith clearError clears errorMessage', () {
      const original = InboxState(
        isLoading: false,
        isRefreshing: false,
        isLoadingMore: false,
        isArchivedMode: false,
        errorMessage: 'error',
        conversations: <ConversationEntity>[],
        page: 1,
        hasMore: true,
      );

      final copy = original.copyWith(clearError: true);

      expect(copy.errorMessage, isNull);
    });
  });
}
