// ─────────────────────────────────────────────────────────────────────────────
//  feed_repository_impl.dart  —  Repository Implementation
//  Bridges data layer → domain layer.
// ─────────────────────────────────────────────────────────────────────────────

import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_sources.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource dataSource;

  const FeedRepositoryImpl({required this.dataSource});

  // ─── Activity Feed ────────────────────────────────────────────────────────

  @override
  Future<FeedPage> getFeed({required int page}) async {
    final model = await dataSource.getFeed(page: page);
    return _mapFeedPage(model);
  }

  // ─── Mappers ──────────────────────────────────────────────────────────────

  FeedPage _mapFeedPage(ActivityFeedPageModel model) {
    print('🟡 items count: ${model.items.length}');
    print('🟡 pagination: ${model.pagination.total}');
    return FeedPage(
      items: model.items.map(_mapFeedItem).toList(),
      page: model.pagination.page,
      hasMore: model.pagination.hasNextPage,
      totalItems: model.pagination.total,
      totalPages: model.pagination.totalPages,
    );
  }

  FeedItem _mapFeedItem(FeedActivityItemModel model) {
    return FeedItem(
      activityId: model.id,
      action: model.actionType,           // 'POST' | 'REPOST'
      timeAgo: _timeAgo(model.activityAt),
      createdAt: model.activityAt,
      actor: _mapActor(model.actor),
      track: _mapTrack(model.track),
    );
  }

  FeedActor _mapActor(FeedActorModel model) {
    return FeedActor(
      userId: model.id,
      displayName: model.displayName,
      handle: model.handle,
      avatarUrl: model.avatarUrl,
      verified: false,                    // not in API yet — default false
    );
  }

  FeedTrack _mapTrack(FeedTrackModel model) {
    final artist = FeedActor(
      userId: model.artistId,
      displayName: model.artistName,
      handle: model.artistHandle,
      avatarUrl: model.artistAvatarUrl,
      verified: false,
    );

    final stats = TrackStats(
      likesCount: model.likesCount,
      commentsCount: model.commentsCount,                   // not in API yet — default 0
      repostsCount: model.repostsCount,
      playsCount: 0,                      // not in API yet — default 0
    );

    final userState = TrackUserState(
      liked: model.liked,
      reposted: model.reposted,
      inLibrary: false,                   // not in API yet — default false
    );

    return FeedTrack(
      trackId: model.id,
      title: model.title,
      slug: model.slug,
      durationMs: model.durationMs ?? 0,
      status: model.status,
      visibility: model.visibility,
      coverArtUrl: model.coverArtUrl,
      genre: '',                          // not in API yet — default empty
      waveformData: model.waveformData,
      artist: artist,
      stats: stats,
      userState: userState,
    );
  }

  /// Converts an ISO-8601 string → human-readable "X ago" string.
  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().toUtc().difference(dt.toUtc());

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';
    return '${(diff.inDays / 365).floor()}y ago';
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
    final source = await getPlaybackAccess(trackId);
    if (!source.canPlay) return null;
    return source.streamUrl;
  }

  @override
  Future<PlaybackAccessResult> getPlaybackAccess(String trackId) async {
    final res = await dataSource.getTrackSource(trackId);
    final accessState = (res['accessState'] as String?) ?? 'BLOCKED';
    return PlaybackAccessResult(
      accessState: accessState,
      streamUrl: res['streamUrl'] as String?,
    );
  }

  @override
  Future<void> recordPlay(String trackId) async {
    await dataSource.recordPlay(trackId);
  }

  // ─── Search ───────────────────────────────────────────────────────────────

  @override
  Future<SearchResults> search({required String query, int page = 1}) async {
    return dataSource.search(query: query, page: page);
  }

  // ─── Trending ─────────────────────────────────────────────────────────────

  @override
  Future<List<TrendingTrack>> getTrending() async {
    return dataSource.getTrending();
  }

  // ─── Resolve ──────────────────────────────────────────────────────────────

  @override
  Future<ResolveResult> resolve(String permalink) async {
    return dataSource.resolve(permalink);
  }
}