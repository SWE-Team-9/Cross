// ─────────────────────────────────────────────────────────────────────────────
//  feed_cubit.dart  —  Presentation Logic
//
//  Manages:
//    ✓ Tab switching   (Discover ↔ Following)
//    ✓ Initial load
//    ✓ Pagination      (infinite scroll → loadMore)
//    ✓ Pull-to-refresh
//    ✓ Optimistic like / repost (instant UI, rollback on error)
//    ✓ Play track      (get stream URL + record play event)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/usecases/get_feed.dart';
import '../../domain/usecases/toggle_like.dart';
import '../../domain/usecases/toggle_repost.dart';
import '../../domain/repositories/feed_repository.dart';
import 'feed_state.dart';

class FeedCubit extends Cubit<FeedState> {
  final GetFeedUseCase _getFeed;
  final ToggleLikeUseCase _toggleLike;
  final ToggleRepostUseCase _toggleRepost;
  final FeedRepository _repository;

  FeedCubit({
    required GetFeedUseCase getFeed,
    required ToggleLikeUseCase toggleLike,
    required ToggleRepostUseCase toggleRepost,
    required FeedRepository repository,
  })  : _getFeed = getFeed,
        _toggleLike = toggleLike,
        _toggleRepost = toggleRepost,
        _repository = repository,
        super(const FeedLoading(FeedTab.following));

  // ─── Tab switching ────────────────────────────────────────────────────────

  Future<void> setTab(FeedTab tab) async {
    if (state.tab == tab && state is FeedLoaded) return;
    emit(FeedLoading(tab));
    await _loadPage(tab: tab, page: 1, reset: true);
  }

  // ─── Initial load ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    emit(FeedLoading(state.tab));
    await _loadPage(tab: state.tab, page: 1, reset: true);
  }

  // ─── Pull-to-refresh ──────────────────────────────────────────────────────

  Future<void> refresh() async {
    final currentTab = state.tab;

    // Keep showing current items while refreshing (no full skeleton)
    if (state is FeedLoaded) {
      emit((state as FeedLoaded).copyWith(isRefreshing: true));
    }

    await _loadPage(tab: currentTab, page: 1, reset: true, isRefresh: true);
  }

  // ─── Infinite scroll ──────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (state is! FeedLoaded) return;
    final loaded = state as FeedLoaded;
    if (!loaded.hasMore || loaded.isLoadingMore) return;

    emit(loaded.copyWith(isLoadingMore: true));
    await _loadPage(tab: loaded.tab, page: loaded.nextPage, reset: false);
  }

  // ─── Core loader ──────────────────────────────────────────────────────────

  Future<void> _loadPage({
    required FeedTab tab,
    required int page,
    required bool reset,
    bool isRefresh = false,
  }) async {
    try {
      final result = await _getFeed(tab: tab.key, page: page);

      if (isClosed) return;

      // Discard if user switched tabs while request was in-flight
      if (state.tab != tab) return;

      if (result.items.isEmpty && reset) {
        emit(FeedEmpty(tab));
        return;
      }

      final previousItems = (!reset && state is FeedLoaded)
          ? (state as FeedLoaded).items
          : <FeedItem>[];

      emit(FeedLoaded(
        tab: tab,
        items: [...previousItems, ...result.items],
        nextPage: page + 1,
        hasMore: result.hasMore,
        isLoadingMore: false,
        isRefreshing: false,
      ));
    } catch (e) {
      if (isClosed) return;
      if (state.tab != tab) return;

      // If we already have items, keep them and show a snackbar (handled in UI)
      if (state is FeedLoaded && !reset) {
        emit((state as FeedLoaded).copyWith(
          isLoadingMore: false,
          isRefreshing: false,
        ));
      } else {
        emit(FeedError(tab, e.toString()));
      }
    }
  }

  // ─── Optimistic Like ──────────────────────────────────────────────────────

  Future<void> handleLike(String trackId) async {
    if (state is! FeedLoaded) return;
    final loaded = state as FeedLoaded;

    final idx = loaded.items.indexWhere((i) => i.track.trackId == trackId);
    if (idx == -1) return;

    final item = loaded.items[idx];
    final wasLiked = item.track.userState.liked;
    final prevCount = item.track.stats.likesCount;

    // 1. Optimistic update
    emit(loaded.copyWith(
      items: _updateTrack(
          loaded.items,
          idx,
          item.copyWith(
            track: item.track.copyWith(
              userState: item.track.userState.copyWith(liked: !wasLiked),
              stats: item.track.stats.copyWith(
                likesCount: wasLiked ? prevCount - 1 : prevCount + 1,
              ),
            ),
          )),
    ));

    try {
      // 2. Real API call
      await _toggleLike(trackId: trackId, currentlyLiked: wasLiked);
    } catch (_) {
      if (isClosed) return;
      // 3. Rollback on error
      if (state is FeedLoaded) {
        final current = state as FeedLoaded;
        final rollbackIdx =
            current.items.indexWhere((i) => i.track.trackId == trackId);
        if (rollbackIdx == -1) return;
        final rollbackItem = current.items[rollbackIdx];
        emit(current.copyWith(
          items: _updateTrack(
              current.items,
              rollbackIdx,
              rollbackItem.copyWith(
                track: rollbackItem.track.copyWith(
                  userState:
                      rollbackItem.track.userState.copyWith(liked: wasLiked),
                  stats:
                      rollbackItem.track.stats.copyWith(likesCount: prevCount),
                ),
              )),
        ));
      }
    }
  }

  // ─── Optimistic Repost ────────────────────────────────────────────────────

  Future<void> handleRepost(String trackId) async {
    if (state is! FeedLoaded) return;
    final loaded = state as FeedLoaded;

    final idx = loaded.items.indexWhere((i) => i.track.trackId == trackId);
    if (idx == -1) return;

    final item = loaded.items[idx];
    final wasReposted = item.track.userState.reposted;
    final prevCount = item.track.stats.repostsCount;

    // 1. Optimistic update
    emit(loaded.copyWith(
      items: _updateTrack(
          loaded.items,
          idx,
          item.copyWith(
            track: item.track.copyWith(
              userState: item.track.userState.copyWith(reposted: !wasReposted),
              stats: item.track.stats.copyWith(
                repostsCount: wasReposted ? prevCount - 1 : prevCount + 1,
              ),
            ),
          )),
    ));

    try {
      await _toggleRepost(trackId: trackId, currentlyReposted: wasReposted);
    } catch (_) {
      if (isClosed) return;
      if (state is FeedLoaded) {
        final current = state as FeedLoaded;
        final rollbackIdx =
            current.items.indexWhere((i) => i.track.trackId == trackId);
        if (rollbackIdx == -1) return;
        final rollbackItem = current.items[rollbackIdx];
        emit(current.copyWith(
          items: _updateTrack(
              current.items,
              rollbackIdx,
              rollbackItem.copyWith(
                track: rollbackItem.track.copyWith(
                  userState: rollbackItem.track.userState
                      .copyWith(reposted: wasReposted),
                  stats: rollbackItem.track.stats
                      .copyWith(repostsCount: prevCount),
                ),
              )),
        ));
      }
    }
  }

  // ─── Play track ───────────────────────────────────────────────────────────

  /// Returns playback access with stream URL (if allowed).
  /// Also fires recordPlay in parallel.
  Future<PlaybackAccessResult> handlePlay(String trackId) async {
    try {
      final access = await _repository.getPlaybackAccess(trackId);
      if (!access.canPlay || access.streamUrl == null) {
        return access;
      }

      await _repository.recordPlay(trackId);
      return access;
    } catch (_) {
      return const PlaybackAccessResult(accessState: 'BLOCKED');
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────

  List<FeedItem> _updateTrack(List<FeedItem> items, int idx, FeedItem updated) {
    final copy = List<FeedItem>.from(items);
    copy[idx] = updated;
    return copy;
  }
}
