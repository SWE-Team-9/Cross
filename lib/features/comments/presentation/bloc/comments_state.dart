import '../../domain/entities/comment_entity.dart';

class CommentsState {
  final bool isLoading;
  final bool isSubmitting;
  final List<CommentEntity> comments;
  final String? errorMessage;

  const CommentsState({
    required this.isLoading,
    required this.isSubmitting,
    required this.comments,
    required this.errorMessage,
  });

  factory CommentsState.initial() {
    return const CommentsState(
      isLoading: false,
      isSubmitting: false,
      comments: [],
      errorMessage: null,
    );
  }

  CommentsState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    List<CommentEntity>? comments,
    String? errorMessage,
    bool clearError = false,
  }) {
    return CommentsState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      comments: comments ?? this.comments,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
