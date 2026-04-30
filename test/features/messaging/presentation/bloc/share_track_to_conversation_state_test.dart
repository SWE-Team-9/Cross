import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/share_track_to_conversation_state.dart';

void main() {
  group('ShareTrackToConversationState', () {
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

    test('initial has expected defaults', () {
      final state = ShareTrackToConversationState.initial();

      expect(state.isLoadingConversations, isFalse);
      expect(state.isSharing, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
      expect(state.conversations, isEmpty);
      expect(state.page, 1);
      expect(state.hasMore, isTrue);
      expect(state.selectedConversationId, isNull);
    });

    test('copyWith keeps existing values when no values are provided', () {
      const original = ShareTrackToConversationState(
        isLoadingConversations: true,
        isSharing: true,
        errorMessage: 'error',
        successMessage: 'success',
        conversations: <ConversationEntity>[conversation],
        page: 2,
        hasMore: false,
        selectedConversationId: 'conversation-1',
      );

      final copy = original.copyWith();

      expect(copy.isLoadingConversations, original.isLoadingConversations);
      expect(copy.isSharing, original.isSharing);
      expect(copy.errorMessage, original.errorMessage);
      expect(copy.successMessage, original.successMessage);
      expect(copy.conversations, original.conversations);
      expect(copy.page, original.page);
      expect(copy.hasMore, original.hasMore);
      expect(copy.selectedConversationId, original.selectedConversationId);
    });

    test('copyWith overrides provided values', () {
      final original = ShareTrackToConversationState.initial();

      final copy = original.copyWith(
        isLoadingConversations: true,
        isSharing: true,
        errorMessage: 'error',
        successMessage: 'success',
        conversations: const <ConversationEntity>[conversation],
        page: 3,
        hasMore: false,
        selectedConversationId: 'conversation-1',
      );

      expect(copy.isLoadingConversations, isTrue);
      expect(copy.isSharing, isTrue);
      expect(copy.errorMessage, 'error');
      expect(copy.successMessage, 'success');
      expect(copy.conversations, const <ConversationEntity>[conversation]);
      expect(copy.page, 3);
      expect(copy.hasMore, isFalse);
      expect(copy.selectedConversationId, 'conversation-1');
    });

    test('copyWith clear flags clear nullable fields', () {
      const original = ShareTrackToConversationState(
        isLoadingConversations: false,
        isSharing: false,
        errorMessage: 'error',
        successMessage: 'success',
        conversations: <ConversationEntity>[],
        page: 1,
        hasMore: true,
        selectedConversationId: 'conversation-1',
      );

      final copy = original.copyWith(
        clearError: true,
        clearSuccess: true,
        clearSelectedConversation: true,
      );

      expect(copy.errorMessage, isNull);
      expect(copy.successMessage, isNull);
      expect(copy.selectedConversationId, isNull);
    });
  });
}
