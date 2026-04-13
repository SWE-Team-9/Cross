import '../../domain/entities/engagement_user.dart';

enum EngagementListType { likers, reposters }

class EngagementListState {
  final bool isLoading;
  final bool isLoadingMore;
  final List<EngagementUser> items;
  final String? errorMessage;
  final int page;
  final bool hasNextPage;
  final EngagementListType type;
  final String trackId;

  const EngagementListState({
    required this.isLoading,
    required this.isLoadingMore,
    required this.items,
    required this.errorMessage,
    required this.page,
    required this.hasNextPage,
    required this.type,
    required this.trackId,
  });

  factory EngagementListState.initial() {
    return const EngagementListState(
      isLoading: false,
      isLoadingMore: false,
      items: [],
      errorMessage: null,
      page: 1,
      hasNextPage: true,
      type: EngagementListType.likers,
      trackId: '',
    );
  }

  EngagementListState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    List<EngagementUser>? items,
    String? errorMessage,
    int? page,
    bool? hasNextPage,
    EngagementListType? type,
    String? trackId,
    bool clearError = false,
  }) {
    return EngagementListState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      items: items ?? this.items,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      page: page ?? this.page,
      hasNextPage: hasNextPage ?? this.hasNextPage,
      type: type ?? this.type,
      trackId: trackId ?? this.trackId,
    );
  }

  String get title =>
      type == EngagementListType.likers ? 'Liked by' : 'Reposted by';
}