class TrackInteractionState {
  final bool isLoading;
  final bool isSubmittingLike;
  final bool isSubmittingRepost;
  final bool isLiked;
  final bool isReposted;
  final int likesCount;
  final int repostsCount;
  final String? errorMessage;

  const TrackInteractionState({
    required this.isLoading,
    required this.isSubmittingLike,
    required this.isSubmittingRepost,
    required this.isLiked,
    required this.isReposted,
    required this.likesCount,
    required this.repostsCount,
    required this.errorMessage,
  });

  factory TrackInteractionState.initial() {
    return const TrackInteractionState(
      isLoading: false,
      isSubmittingLike: false,
      isSubmittingRepost: false,
      isLiked: false,
      isReposted: false,
      likesCount: 0,
      repostsCount: 0,
      errorMessage: null,
    );
  }

  TrackInteractionState copyWith({
    bool? isLoading,
    bool? isSubmittingLike,
    bool? isSubmittingRepost,
    bool? isLiked,
    bool? isReposted,
    int? likesCount,
    int? repostsCount,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TrackInteractionState(
      isLoading: isLoading ?? this.isLoading,
      isSubmittingLike: isSubmittingLike ?? this.isSubmittingLike,
      isSubmittingRepost: isSubmittingRepost ?? this.isSubmittingRepost,
      isLiked: isLiked ?? this.isLiked,
      isReposted: isReposted ?? this.isReposted,
      likesCount: likesCount ?? this.likesCount,
      repostsCount: repostsCount ?? this.repostsCount,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}