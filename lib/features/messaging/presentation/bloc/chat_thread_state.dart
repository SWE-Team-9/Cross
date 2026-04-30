import '../../domain/entities/message_entity.dart';

class ChatThreadState {
  final bool isLoading;
  final bool isSending;
  final bool isLoadingMore;
  final bool isSocketConnected;
  final String? errorMessage;
  final List<MessageEntity> messages;
  final int page;
  final bool hasMore;

  const ChatThreadState({
    required this.isLoading,
    required this.isSending,
    required this.isLoadingMore,
    required this.isSocketConnected,
    required this.errorMessage,
    required this.messages,
    required this.page,
    required this.hasMore,
  });

  factory ChatThreadState.initial() {
    return const ChatThreadState(
      isLoading: false,
      isSending: false,
      isLoadingMore: false,
      isSocketConnected: false,
      errorMessage: null,
      messages: [],
      page: 1,
      hasMore: true,
    );
  }

  ChatThreadState copyWith({
    bool? isLoading,
    bool? isSending,
    bool? isLoadingMore,
    bool? isSocketConnected,
    String? errorMessage,
    bool clearError = false,
    List<MessageEntity>? messages,
    int? page,
    bool? hasMore,
  }) {
    return ChatThreadState(
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isSocketConnected: isSocketConnected ?? this.isSocketConnected,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      messages: messages ?? this.messages,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}
