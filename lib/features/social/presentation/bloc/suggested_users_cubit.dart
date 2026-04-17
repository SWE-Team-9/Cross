import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';

import '../../data/repositories/social_repo.dart';
import '../../domain/entities/user.dart';
import '../../domain/events/social_events.dart';

part 'suggested_users_state.dart';

class SuggestedUsersCubit extends Cubit<SuggestedUsersState> {
  SuggestedUsersCubit(this._repo) : super(const SuggestedUsersState());

  final SocialRepo _repo;
  static const int _pageLimit = 20;

  Future<void> loadInitial() async {
    emit(
      state.copyWith(
        isLoading: true,
        users: const <User>[],
        hasMore: true,
        currentPage: 0,
        clearError: true,
      ),
    );
    await _fetchPage(1);
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    emit(state.copyWith(isLoading: true, clearError: true));
    await _fetchPage(state.currentPage + 1);
  }

  Future<void> _fetchPage(int page) async {
    try {
      final fetched = await _repo.getSuggestedUsers(page: page, limit: _pageLimit);
      final merged = page == 1 ? fetched : [...state.users, ...fetched];
      emit(
        state.copyWith(
          users: merged,
          isLoading: false,
          currentPage: page,
          hasMore: fetched.length >= _pageLimit,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> toggleFollow(User user) async {
    final snapshot = List<User>.from(state.users);
    final bool newFollowing = !user.isFollowing;
    final optimistic = state.users.map((u) {
      if (u.id != user.id) return u;
      return u.copyWith(
        isFollowing: newFollowing,
        followersCount:
            newFollowing ? u.followersCount + 1 : u.followersCount - 1,
      );
    }).toList();
    emit(state.copyWith(users: optimistic, clearError: true));

    try {
      if (newFollowing) {
        final result = await _repo.followUser(user.id);
        final confirmed = state.users.map((u) {
          if (u.id != user.id) return u;
          return u.copyWith(
            isFollowing: result.isFollowing,
            followersCount: result.followersCount,
          );
        }).toList();
        emit(state.copyWith(users: confirmed, clearError: true));
      } else {
        final result = await _repo.unfollowUser(user.id);
        final confirmed = state.users.map((u) {
          if (u.id != user.id) return u;
          return u.copyWith(
            isFollowing: result.isFollowing,
            followersCount: result.followersCount ?? u.followersCount,
          );
        }).toList();
        emit(state.copyWith(users: confirmed, clearError: true));
      }
      SocialEvents.emitFollowChanged();
    } catch (_) {
      emit(state.copyWith(users: snapshot));
    }
  }
}
