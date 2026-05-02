class UnreadCountState {
  final bool isLoading;
  final int count;
  final String? errorMessage;

  const UnreadCountState({
    required this.isLoading,
    required this.count,
    required this.errorMessage,
  });

  factory UnreadCountState.initial() {
    return const UnreadCountState(
      isLoading: false,
      count: 0,
      errorMessage: null,
    );
  }

  UnreadCountState copyWith({
    bool? isLoading,
    int? count,
    String? errorMessage,
    bool clearError = false,
  }) {
    return UnreadCountState(
      isLoading: isLoading ?? this.isLoading,
      count: count ?? this.count,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
