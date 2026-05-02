// ─────────────────────────────────────────────────────────────────────────────
//  test_helpers.dart  —  Shared fakes & factories for all feed tests
// ─────────────────────────────────────────────────────────────────────────────

import 'package:soundcloud_clone/features/feed/domain/entities/feed_item.dart';
import 'package:soundcloud_clone/features/feed/domain/repositories/feed_repository.dart';

// ─── Fake Repository ─────────────────────────────────────────────────────────

class FakeFeedRepository implements FeedRepository {
  FeedPage? feedPageToReturn;

  Exception? getFeedError;
  Exception? toggleLikeError;
  Exception? toggleRepostError;
  Exception? streamUrlError;

  List<String> getCalls = [];
  List<String> likeCalls = [];
  List<String> repostCalls = [];
  List<String> playCalls = [];

  String? streamUrlResult = 'https://cdn.mock.com/track.mp3';

  @override
  Future<FeedPage> getFeed({required int page}) async {
    getCalls.add('$page:$page');
    if (getFeedError != null) throw getFeedError!;
    return feedPageToReturn ?? makeFeedPage(page: page);
  }

  @override
  Future<({int likesCount, bool liked})> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  }) async {
    if (toggleLikeError != null) throw toggleLikeError!;
    likeCalls.add(trackId);
    return (likesCount: currentlyLiked ? 99 : 101, liked: !currentlyLiked);
  }

  @override
  Future<({int repostsCount, bool reposted})> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  }) async {
    if (toggleRepostError != null) throw toggleRepostError!;
    repostCalls.add(trackId);
    return (
      repostsCount: currentlyReposted ? 9 : 11,
      reposted: !currentlyReposted,
    );
  }

  @override
  Future<String?> getStreamUrl(String trackId) async {
    if (streamUrlError != null) throw streamUrlError!;
    return streamUrlResult;
  }

  @override
  Future<PlaybackAccessResult> getPlaybackAccess(String trackId) async {
    if (streamUrlError != null) throw streamUrlError!;
    return PlaybackAccessResult(
      accessState: streamUrlResult == null ? 'BLOCKED' : 'PLAYABLE',
      streamUrl: streamUrlResult,
    );
  }

  @override
  Future<void> recordPlay(String trackId) async {
    playCalls.add(trackId);
  }

  @override
  Future<List<TrendingTrack>> getTrending() async => [];

  @override
  Future<SearchResults> search({required String query, int page = 1}) async =>
      SearchResults(
        users: [],
        tracks: [],
        playlists: [],
        currentPage: page,
        totalResults: 0,
        totalPages: 1,
      );

  @override
  Future<ResolveResult> resolve(String permalink) async => ResolveResult(
        type: 'TRACK',
        resourceId: permalink,
      );
}

// ─── Factory helpers ──────────────────────────────────────────────────────────

FeedActor makeActor({
  String userId = 'usr_001',
  String displayName = 'Test User',
  String handle = 'test-user',
  bool verified = false,
}) =>
    FeedActor(
      userId: userId,
      displayName: displayName,
      handle: handle,
      verified: verified,
    );

TrackStats makeStats({
  int likes = 100,
  int comments = 10,
  int reposts = 5,
  int plays = 500,
}) =>
    TrackStats(
      likesCount: likes,
      commentsCount: comments,
      repostsCount: reposts,
      playsCount: plays,
    );

TrackUserState makeUserState({
  bool liked = false,
  bool reposted = false,
  bool inLibrary = false,
}) =>
    TrackUserState(liked: liked, reposted: reposted, inLibrary: inLibrary);

FeedTrack makeTrack({
  String trackId = 'trk_001',
  String title = 'Test Track',
  int durationMs = 143000,
  bool liked = false,
  bool reposted = false,
  int likes = 100,
  int reposts = 5,
}) =>
    FeedTrack(
      trackId: trackId,
      title: title,
      slug: trackId,
      durationMs: durationMs,
      status: 'FINISHED',
      visibility: 'PUBLIC',
      genre: 'Electronic',
      artist: makeActor(),
      stats: makeStats(likes: likes, reposts: reposts),
      userState: makeUserState(liked: liked, reposted: reposted),
    );

FeedItem makeItem({
  String activityId = 'act_001',
  String action = 'posted a track',
  String trackId = 'trk_001',
  bool liked = false,
  bool reposted = false,
  int likes = 100,
  int reposts = 5,
}) =>
    FeedItem(
      activityId: activityId,
      action: action,
      timeAgo: '2 hours ago',
      actor: makeActor(),
      track: makeTrack(
        trackId: trackId,
        liked: liked,
        reposted: reposted,
        likes: likes,
        reposts: reposts,
      ),
    );

FeedPage makeFeedPage({
  String tab = 'following',
  int page = 1,
  int count = 3,
  bool hasMore = true,
}) =>
    FeedPage(
      items: List.generate(
        count,
        (i) => makeItem(
          activityId: 'act_${tab}_${page}_$i',
          trackId: 'trk_${tab}_${page}_$i',
        ),
      ),
      page: page,
      hasMore: hasMore,
      totalItems: count * 4,
      totalPages: (count * 4 / count).ceil(),
    );

FeedPage makeEmptyPage() => const FeedPage(
      items: [],
      page: 1,
      hasMore: false,
      totalItems: 0,
      totalPages: 1,
    );

void main() {}
