import '../../domain/entities/conversation_entity.dart';

class StartDirectConversationState {
  final bool isLoading;
  final String? errorMessage;
  final ConversationEntity? conversation;

  const StartDirectConversationState({
    required this.isLoading,
    required this.errorMessage,
    required this.conversation,
  });

  factory StartDirectConversationState.initial() {
    return const StartDirectConversationState(
      isLoading: false,
      errorMessage: null,
      conversation: null,
    );
  }

  StartDirectConversationState copyWith({
    bool? isLoading,
    String? errorMessage,
    bool clearError = false,
    ConversationEntity? conversation,
    bool clearConversation = false,
  }) {
    return StartDirectConversationState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      conversation:
          clearConversation ? null : (conversation ?? this.conversation),
    );
  }
}