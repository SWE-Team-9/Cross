import 'package:bloc/bloc.dart';
import 'package:soundcloud_clone/features/social/domain/entities/user.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

part 'blocked_users_state.dart';

class BlockedUsersCubit extends Cubit<BlockedUsersState> {
  final SocialRepo repo;

  static const int _pageLimit = 20;

  BlockedUsersCubit(this.repo) : super(const BlockedUsersState(users: []));

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
      final fetched = await repo.getBlockedUsers(page, limit: _pageLimit);

      final allUsers = page == 1 ? fetched : [...state.users, ...fetched];

      emit(state.copyWith(
        users: allUsers,
        loading: false,
        currentPage: page,
        hasMore: fetched.length >= _pageLimit,
        error: null,
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString(),
      ));
    }
  }

  Future<void> unblockUser(User user) async {
    final snapshot = List<User>.from(state.users);

    // Optimistic: شيله من الليست فوراً
    final optimistic = state.users.where((u) => u.id != user.id).toList();
    emit(state.copyWith(users: optimistic));

    try {
      final success = await repo.unblockUser(user.id);
      if (!success) {
        emit(state.copyWith(users: snapshot));
      }
    } catch (_) {
      emit(state.copyWith(users: snapshot));
    }
  }
}
