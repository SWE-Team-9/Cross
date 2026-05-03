part of 'follow_cubit.dart';

class FollowState {
  final List<User> users;
  final bool loading;
  final bool hasMore;
  final int currentPage;
  final String? error;
  final Set<String> loadingIds; // ✅ جديد

  const FollowState({
    required this.users,
    this.loading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
    this.loadingIds = const {}, // ✅ جديد
  });

  FollowState copyWith({
    List<User>? users,
    bool? loading,
    bool? hasMore,
    int? currentPage,
    String? error,
    Set<String>? loadingIds, // ✅ جديد
  }) {
    return FollowState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: error,
      loadingIds: loadingIds ?? this.loadingIds, // ✅ جديد
    );
  }
}
