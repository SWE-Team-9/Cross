import '../../domain/entities/feed_item.dart';
import '../../domain/repositories/feed_repository.dart';
import '../datasources/feed_remote_data_sources.dart';

class FeedRepositoryImpl implements FeedRepository {
  final FeedRemoteDataSource dataSource;

  const FeedRepositoryImpl({required this.dataSource});

  @override
  Future<FeedPage> getFeed({required int page}) async {
    final model = await dataSource.getFeed(page: page);
    return _mapFeedPage(model);
  }

  FeedPage _mapFeedPage(ActivityFeedPageModel model) {
    return FeedPage(
      items: model.items.map(_mapFeedItem).toList(growable: false),
      page: model.pagination.page,
      hasMore: model.pagination.hasNextPage,
      totalItems: model.pagination.total,
      totalPages: model.pagination.totalPages,
    );
  }

  FeedItem _mapFeedItem(FeedActivityItemModel model) {
    return FeedItem(
      activityId: model.id,
      action: model.actionType,
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
      verified: model.verified,
    );
  }

  FeedTrack _mapTrack(FeedTrackModel model) {
    return FeedTrack(
      trackId: model.id,
      title: model.title,
      slug: model.slug,
      durationMs: model.durationMs ?? 0,
      status: model.status,
      visibility: model.visibility,
      coverArtUrl: model.coverArtUrl,
      genre: model.genre,
      waveformData: model.waveformData,
      audioUrl: model.audioUrl,
      artist: FeedActor(
        userId: model.artistId,
        displayName: model.artistName,
        handle: model.artistHandle,
        avatarUrl: model.artistAvatarUrl,
        verified: false,
      ),
      stats: TrackStats(
        likesCount: model.likesCount,
        commentsCount: model.commentsCount,
        repostsCount: model.repostsCount,
        playsCount: model.playsCount,
      ),
      userState: TrackUserState(
        liked: model.liked,
        reposted: model.reposted,
        inLibrary: false,
      ),
    );
  }

  String _timeAgo(String? iso) {
    if (iso == null || iso.isEmpty) return '';

    final dateTime = DateTime.tryParse(iso);
    if (dateTime == null) return '';

    final diff = DateTime.now().toUtc().difference(dateTime.toUtc());

    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    if (diff.inDays < 30) return '${(diff.inDays / 7).floor()}w ago';
    if (diff.inDays < 365) return '${(diff.inDays / 30).floor()}mo ago';

    return '${(diff.inDays / 365).floor()}y ago';
  }

  @override
  Future<({int likesCount, bool liked})> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  }) async {
    final response = await dataSource.toggleLike(
      trackId: trackId,
      currentlyLiked: currentlyLiked,
    );

    return (
      likesCount: (response['likesCount'] as int?) ?? 0,
      liked: (response['liked'] as bool?) ?? !currentlyLiked,
    );
  }

  @override
  Future<({int repostsCount, bool reposted})> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  }) async {
    final response = await dataSource.toggleRepost(
      trackId: trackId,
      currentlyReposted: currentlyReposted,
    );

    return (
      repostsCount: (response['repostsCount'] as int?) ?? 0,
      reposted: (response['reposted'] as bool?) ?? !currentlyReposted,
    );
  }

  @override
  Future<String?> getStreamUrl(String trackId) async {
    final source = await getPlaybackAccess(trackId);
    if (!source.canPlay) return null;
    return source.streamUrl;
  }

  @override
  Future<PlaybackAccessResult> getPlaybackAccess(String trackId) async {
    final response = await dataSource.getTrackSource(trackId);

    return PlaybackAccessResult(
      accessState: (response['accessState'] as String?) ?? 'BLOCKED',
      streamUrl: response['streamUrl'] as String?,
    );
  }

  @override
  Future<void> recordPlay(String trackId) async {
    await dataSource.recordPlay(trackId);
  }

  @override
  Future<SearchResults> search({
    required String query,
    int page = 1,
  }) {
    return dataSource.search(query: query, page: page);
  }

  @override
  Future<List<TrendingTrack>> getTrending() {
    return dataSource.getTrending();
  }

  @override
  Future<ResolveResult> resolve(String permalink) {
    return dataSource.resolve(permalink);
  }
}
