part of 'suggested_users_cubit.dart';

class SuggestedUsersState extends Equatable {
  const SuggestedUsersState({
    this.users = const <User>[],
    this.isLoading = false,
    this.hasMore = true,
    this.currentPage = 0,
    this.error,
  });

  final List<User> users;
  final bool isLoading;
  final bool hasMore;
  final int currentPage;
  final String? error;

  SuggestedUsersState copyWith({
    List<User>? users,
    bool? isLoading,
    bool? hasMore,
    int? currentPage,
    String? error,
    bool clearError = false,
  }) {
    return SuggestedUsersState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      error: clearError ? null : (error ?? this.error),
    );
  }

  @override
  List<Object?> get props => [users, isLoading, hasMore, currentPage, error];
}
