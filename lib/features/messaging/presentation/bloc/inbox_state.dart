import '../../domain/entities/conversation_entity.dart';

class InboxState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingMore;
  final String? errorMessage;
  final List<ConversationEntity> conversations;
  final int page;
  final bool hasMore;

  const InboxState({
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingMore,
    required this.errorMessage,
    required this.conversations,
    required this.page,
    required this.hasMore,
  });

  factory InboxState.initial() {
    return const InboxState(
      isLoading: false,
      isRefreshing: false,
      isLoadingMore: false,
      errorMessage: null,
      conversations: [],
      page: 1,
      hasMore: true,
    );
  }

  InboxState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingMore,
    String? errorMessage,
    bool clearError = false,
    List<ConversationEntity>? conversations,
    int? page,
    bool? hasMore,
  }) {
    return InboxState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      conversations: conversations ?? this.conversations,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}