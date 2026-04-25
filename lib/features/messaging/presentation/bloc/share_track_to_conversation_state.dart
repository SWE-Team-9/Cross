import '../../domain/entities/conversation_entity.dart';

class ShareTrackToConversationState {
  final bool isLoadingConversations;
  final bool isSharing;
  final String? errorMessage;
  final String? successMessage;
  final List<ConversationEntity> conversations;
  final int page;
  final bool hasMore;
  final String? selectedConversationId;

  const ShareTrackToConversationState({
    required this.isLoadingConversations,
    required this.isSharing,
    required this.errorMessage,
    required this.successMessage,
    required this.conversations,
    required this.page,
    required this.hasMore,
    required this.selectedConversationId,
  });

  factory ShareTrackToConversationState.initial() {
    return const ShareTrackToConversationState(
      isLoadingConversations: false,
      isSharing: false,
      errorMessage: null,
      successMessage: null,
      conversations: [],
      page: 1,
      hasMore: true,
      selectedConversationId: null,
    );
  }

  ShareTrackToConversationState copyWith({
    bool? isLoadingConversations,
    bool? isSharing,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
    List<ConversationEntity>? conversations,
    int? page,
    bool? hasMore,
    String? selectedConversationId,
    bool clearSelectedConversation = false,
  }) {
    return ShareTrackToConversationState(
      isLoadingConversations:
          isLoadingConversations ?? this.isLoadingConversations,
      isSharing: isSharing ?? this.isSharing,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage:
          clearSuccess ? null : (successMessage ?? this.successMessage),
      conversations: conversations ?? this.conversations,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      selectedConversationId: clearSelectedConversation
          ? null
          : (selectedConversationId ?? this.selectedConversationId),
    );
  }
}