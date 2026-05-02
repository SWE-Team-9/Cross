// ─────────────────────────────────────────────────────────────────────────────
//  feed_repository.dart  —  Domain Repository (Abstract)
// ─────────────────────────────────────────────────────────────────────────────

import '../entities/feed_item.dart';

class PlaybackAccessResult {
  const PlaybackAccessResult({
    required this.accessState,
    this.streamUrl,
  });

  final String accessState; // PLAYABLE | PREVIEW | BLOCKED
  final String? streamUrl;

  bool get isBlocked => accessState == 'BLOCKED';
  bool get isPreview => accessState == 'PREVIEW';
  bool get canPlay => accessState == 'PLAYABLE' || accessState == 'PREVIEW';
}

abstract class FeedRepository {
  // ── Activity Feed ──────────────────────────────────────────────────────────
  /// GET /api/v1/feed
  Future<FeedPage> getFeed({required int page});

  // ── Interactions ───────────────────────────────────────────────────────────
  /// POST   /api/v1/interactions/tracks/{trackId}/like
  /// DELETE /api/v1/interactions/tracks/{trackId}/like
  Future<({int likesCount, bool liked})> toggleLike({
    required String trackId,
    required bool currentlyLiked,
  });

  /// POST   /api/v1/interactions/tracks/{trackId}/repost
  /// DELETE /api/v1/interactions/tracks/{trackId}/repost
  Future<({int repostsCount, bool reposted})> toggleRepost({
    required String trackId,
    required bool currentlyReposted,
  });

  // ── Playback ───────────────────────────────────────────────────────────────
  /// GET  /api/v1/player/tracks/{trackId}/source
  Future<String?> getStreamUrl(String trackId);

  /// GET /api/v1/player/tracks/{trackId}/source with access behaviour
  Future<PlaybackAccessResult> getPlaybackAccess(String trackId);

  /// POST /api/v1/player/tracks/{trackId}/play
  Future<void> recordPlay(String trackId);

  // ── Discovery ──────────────────────────────────────────────────────────────
  /// GET /api/v1/discovery/search?q=&page=
  Future<SearchResults> search({required String query, int page = 1});

  /// GET /api/v1/discovery/trending
  Future<List<TrendingTrack>> getTrending();

  /// GET /api/v1/discovery/resolve?url=
  Future<ResolveResult> resolve(String permalink);
}
