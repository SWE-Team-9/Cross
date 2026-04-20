part of 'blocked_users_cubit.dart';

class BlockedUsersState {
  final List<User> users;
  final bool loading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  const BlockedUsersState({
    required this.users,
    this.loading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  BlockedUsersState copyWith({
    List<User>? users,
    bool? loading,
    bool? hasMore,
    int? currentPage,
    String? error,
  }) {
    return BlockedUsersState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
    );
  }
}
