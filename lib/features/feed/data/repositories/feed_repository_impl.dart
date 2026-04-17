// ─────────────────────────────────────────────────────────────────────────────
//  feed_repository_impl.dart  —  Repository Implementation
//  Bridges data layer → domain layer.
//  To switch mock → real: inject FeedRemoteDataSourceImpl instead of mock.
// ─────────────────────────────────────────────────────────────────────────────

import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_sources.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource dataSource;

  const FeedRepositoryImpl({required this.dataSource});

  // ─── Feed ─────────────────────────────────────────────────────────────────

  @override
  Future<FeedPage> getFeed({required String tab, required int page}) async {
    final model = await dataSource.getFeed(tab: tab, page: page);
    return model; // FeedPageModel extends FeedPage
  }

  // ─── Like ─────────────────────────────────────────────────────────────────

  @override
  Future<({int likesCount, bool liked})> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  }) async {
    final res = await dataSource.toggleLike(
      trackId: trackId,
      currentlyLiked: currentlyLiked,
    );
    return (
      likesCount: (res['likesCount'] as int?) ?? 0,
      liked: (res['liked'] as bool?) ?? !currentlyLiked,
    );
  }

  // ─── Repost ───────────────────────────────────────────────────────────────

  @override
  Future<({int repostsCount, bool reposted})> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  }) async {
    final res = await dataSource.toggleRepost(
      trackId: trackId,
      currentlyReposted: currentlyReposted,
    );
    return (
      repostsCount: (res['repostsCount'] as int?) ?? 0,
      reposted: (res['reposted'] as bool?) ?? !currentlyReposted,
    );
  }

  // ─── Playback ─────────────────────────────────────────────────────────────

  @override
  Future<String?> getStreamUrl(String trackId) async {
    final res = await dataSource.getTrackSource(trackId);
    final accessState = res['accessState'] as String?;
    if (accessState != 'PLAYABLE') return null;
    return res['streamUrl'] as String?;
  }

  @override
  Future<void> recordPlay(String trackId) async {
    await dataSource.recordPlay(trackId);
  }
}
