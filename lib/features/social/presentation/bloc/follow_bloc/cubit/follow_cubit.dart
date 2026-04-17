import 'package:bloc/bloc.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/domain/events/social_events.dart';

part 'follow_state.dart';

enum FollowListMode { followers, following }

class FollowCubit extends Cubit<FollowState> {
  final SocialRepo repo;
  final String userId;
  final FollowListMode mode;

  static const int _pageLimit = 20;

  FollowCubit({
    required this.repo,
    required this.userId,
    required this.mode,
  }) : super(const FollowState(users: []));

  Future<void> loadInitial() async {
    emit(state.copyWith(
        loading: true, users: [], currentPage: 0, hasMore: true));
    await _fetchPage(1);
  }

  Future<void> loadMore() async {
    if (state.loading || !state.hasMore) return;
    emit(state.copyWith(loading: true));
    await _fetchPage(state.currentPage + 1);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final List<User> fetched = mode == FollowListMode.followers
          ? await repo.getFollowers(userId, page, limit: _pageLimit)
          : await repo.getFollowing(userId, page, limit: _pageLimit);

      final allUsers = page == 1 ? fetched : [...state.users, ...fetched];

      emit(state.copyWith(
        users: allUsers,
        loading: false,
        currentPage: page,
        hasMore: fetched.length >= _pageLimit,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(loading: false, error: e.toString()));
    }
  }

  Future<void> toggleFollow(User user) async {
    final snapshot = List<User>.from(state.users);

    // 1️⃣ Optimistic update فوري
    final newFollowing = !user.isFollowing;
    final optimistic = state.users.map((u) {
      if (u.id != user.id) return u;
      return u.copyWith(
        isFollowing: newFollowing,
        followersCount:
            newFollowing ? u.followersCount + 1 : u.followersCount - 1,
      );
    }).toList();

    emit(state.copyWith(users: optimistic));

    try {
      // 2️⃣ API call وجيب القيم الحقيقية من الـ response
      if (newFollowing) {
        final result = await repo.followUser(user.id);
        // 3️⃣ تحديث بالقيم الحقيقية من الـ API
        final confirmed = state.users.map((u) {
          if (u.id != user.id) return u;
          return u.copyWith(
            isFollowing: result.isFollowing,
            followersCount: result.followersCount,
          );
        }).toList();
        emit(state.copyWith(users: confirmed));
        SocialEvents.emitFollowChanged();
      } else {
        final result = await repo.unfollowUser(user.id);
        final confirmed = state.users.map((u) {
          if (u.id != user.id) return u;
          return u.copyWith(
            isFollowing: result.isFollowing,
            followersCount: result.followersCount ?? u.followersCount,
          );
        }).toList();
        emit(state.copyWith(users: confirmed));
        SocialEvents.emitFollowChanged();
      }
    } catch (_) {
      // 4️⃣ Rollback لو في exception
      emit(state.copyWith(users: snapshot));
    }
  }

  Future<void> unfollowUser(User user) async {
    final snapshot = List<User>.from(state.users);

    // Optimistic: شيله من الليست فوراً
    final optimistic = state.users.where((u) => u.id != user.id).toList();
    emit(state.copyWith(users: optimistic));

    try {
      final result = await repo.unfollowUser(user.id);
      // لو الـ API قال إنه لسه following يرجعه
      if (result.isFollowing) {
        emit(state.copyWith(users: snapshot));
      } else {
        SocialEvents.emitFollowChanged();
      }
    } catch (_) {
      emit(state.copyWith(users: snapshot));
    }
  }

  Future<void> blockUser(User user) async {
    final snapshot = List<User>.from(state.users);

    // Optimistic: شيله من الليست فوراً
    final optimistic = state.users.where((u) => u.id != user.id).toList();
    emit(state.copyWith(users: optimistic));

    try {
      final success = await repo.blockUser(user.id);
      if (!success) {
        emit(state.copyWith(users: snapshot));
      }
    } catch (_) {
      emit(state.copyWith(users: snapshot));
    }
  }
}
