part of 'follow_cubit.dart';

@freezed
class FollowState {
  final List<User> users;
  final bool loading;

  FollowState({
    required this.users,
    this.loading = false,
  });

  FollowState copyWith({
    List<User>? users,
    bool? loading,
  }) {
    return FollowState(
      users: users ?? this.users,
      loading: loading ?? this.loading,
    );
  }
}
