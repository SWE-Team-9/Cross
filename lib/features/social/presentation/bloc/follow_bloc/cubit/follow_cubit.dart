import 'package:bloc/bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

part 'follow_state.dart';



class FollowCubit extends Cubit<FollowState> {
  final SocialRepo repo;

  FollowCubit(this.repo)
      : super(FollowState(users: [
          User(id: "1", username: "Ahmed", followersCount: 10),
          User(id: "2", username: "Ali", followersCount: 20),
        ]));

  Future<void> toggleFollow(User user) async {
    final oldUsers = List<User>.from(state.users);

    // 1️⃣ Optimistic update
    final updated = state.users.map((u) {
      if (u.id == user.id) {
        final newFollow = !u.isFollowing;

        return u.copyWith(
          isFollowing: newFollow,
          followersCount: newFollow
              ? u.followersCount + 1
              : u.followersCount - 1,
        );
      }
      return u;
    }).toList();

    emit(state.copyWith(users: updated));

    // 2️⃣ API call
    final success = user.isFollowing
        ? await repo.unfollowUser(user.id)
        : await repo.followUser(user.id);

    // 3️⃣ rollback لو فشل
    if (!success) {
      emit(state.copyWith(users: oldUsers));
    }
  }
}