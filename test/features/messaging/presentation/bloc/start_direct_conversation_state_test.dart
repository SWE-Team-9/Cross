import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/conversation_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/participant_entity.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/start_direct_conversation_state.dart';

void main() {
  group('StartDirectConversationState', () {
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
      final state = StartDirectConversationState.initial();

      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.conversation, isNull);
    });

    test('copyWith keeps existing values when no values are provided', () {
      const original = StartDirectConversationState(
        isLoading: true,
        errorMessage: 'error',
        conversation: conversation,
      );

      final copy = original.copyWith();

      expect(copy.isLoading, original.isLoading);
      expect(copy.errorMessage, original.errorMessage);
      expect(copy.conversation, original.conversation);
    });

    test('copyWith overrides provided values', () {
      final original = StartDirectConversationState.initial();

      final copy = original.copyWith(
        isLoading: true,
        errorMessage: 'error',
        conversation: conversation,
      );

      expect(copy.isLoading, isTrue);
      expect(copy.errorMessage, 'error');
      expect(copy.conversation, conversation);
    });

    test('copyWith clear flags clear nullable fields', () {
      const original = StartDirectConversationState(
        isLoading: false,
        errorMessage: 'error',
        conversation: conversation,
      );

      final copy = original.copyWith(
        clearError: true,
        clearConversation: true,
      );

      expect(copy.errorMessage, isNull);
      expect(copy.conversation, isNull);
    });
  });
}
