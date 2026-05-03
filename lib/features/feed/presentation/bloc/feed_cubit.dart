// ─────────────────────────────────────────────────────────────────────────────
//  feed_cubit.dart  —  Presentation Logic
//
//  Manages:
//    ✓ Initial load           (GET /api/v1/feed)
//    ✓ Pagination             (infinite scroll → loadMore)
//    ✓ Pull-to-refresh
//    ✓ Optimistic like / repost (instant UI, rollback on error)
//    ✓ Play track             (get stream URL + record play event)
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../domain/entities/feed_item.dart';
import '../../domain/usecases/get_feed.dart';
import '../../domain/usecases/toggle_like.dart';
import '../../domain/usecases/toggle_repost.dart';
import '../../domain/repositories/feed_repository.dart';
import 'feed_state.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  FeedCubit  —  Activity Feed
// ─────────────────────────────────────────────────────────────────────────────

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
        super(const FeedLoading());

  // ─── Initial load ─────────────────────────────────────────────────────────

  Future<void> initialize() async {
    emit(const FeedLoading());
    await _loadPage(page: 1, reset: true);
  }

  // ─── Pull-to-refresh ──────────────────────────────────────────────────────

  Future<void> refresh() async {
    if (state is FeedLoaded) {
      emit((state as FeedLoaded).copyWith(isRefreshing: true));
    }
    await _loadPage(page: 1, reset: true, isRefresh: true);
  }

  // ─── Infinite scroll ──────────────────────────────────────────────────────

  Future<void> loadMore() async {
    if (state is! FeedLoaded) return;
    final loaded = state as FeedLoaded;
    if (!loaded.hasMore || loaded.isLoadingMore) return;

    emit(loaded.copyWith(isLoadingMore: true));
    await _loadPage(page: loaded.nextPage, reset: false);
  }

  // ─── Core loader ──────────────────────────────────────────────────────────

  Future<void> _loadPage({
    required int page,
    required bool reset,
    bool isRefresh = false,
  }) async {
    try {
      final result = await _getFeed(page: page);

      if (isClosed) return;

      if (result.items.isEmpty && reset) {
        emit(const FeedEmpty());
        return;
      }

      final previousItems = (!reset && state is FeedLoaded)
          ? (state as FeedLoaded).items
          : <FeedItem>[];

      emit(FeedLoaded(
        items: [...previousItems, ...result.items],
        nextPage: page + 1,
        hasMore: result.hasMore,
        isLoadingMore: false,
        isRefreshing: false,
      ));
    } catch (e) {
      if (isClosed) return;

      if (state is FeedLoaded && !reset) {
        emit((state as FeedLoaded).copyWith(
          isLoadingMore: false,
          isRefreshing: false,
        ));
      } else {
        // مؤقتاً عشان نشوف الـ error الحقيقي
        emit(FeedError('$e\n${StackTrace.current}'));
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
        ),
      ),
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
                stats: rollbackItem.track.stats.copyWith(likesCount: prevCount),
              ),
            ),
          ),
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
        ),
      ),
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
                stats:
                    rollbackItem.track.stats.copyWith(repostsCount: prevCount),
              ),
            ),
          ),
        ));
      }
    }
  }

  // ─── Play track ───────────────────────────────────────────────────────────

  /// Returns playback access with stream URL (if allowed).
  /// Prefers audio_url from feed payload; falls back to /source endpoint.
  /// Also fires recordPlay in parallel.
  Future<PlaybackAccessResult> handlePlay(
    String trackId, {
    String? feedAudioUrl,
  }) async {
    try {
      // If the feed already gave us an audio_url, use it directly
      if (feedAudioUrl != null && feedAudioUrl.isNotEmpty) {
        await _repository.recordPlay(trackId);
        return PlaybackAccessResult(
          accessState: 'PLAYABLE',
          streamUrl: feedAudioUrl,
        );
      }

      // Otherwise resolve via /source endpoint
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
