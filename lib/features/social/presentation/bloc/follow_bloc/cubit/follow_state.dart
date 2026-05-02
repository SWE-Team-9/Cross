part of 'follow_cubit.dart';

class FollowState {
  final List<User> users;
  final bool loading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const FollowState({
    required this.users,
    this.loading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  FollowState copyWith({
    List<User>? users,
    bool? loading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return FollowState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}
