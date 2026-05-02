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
  /// GET /api/v1/users/{userId}/tracks   (Following tab)
  /// GET /api/v1/social/suggestions      (Discover tab)
  Future<FeedPage> getFeed({
    required String tab, // 'following' | 'discover'
    required int page,
  });

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

  /// GET  /api/v1/player/tracks/{trackId}/source
  Future<String?> getStreamUrl(String trackId);

  /// GET /api/v1/player/tracks/{trackId}/source with access behavior
  Future<PlaybackAccessResult> getPlaybackAccess(String trackId);

  /// POST /api/v1/player/tracks/{trackId}/play
  Future<void> recordPlay(String trackId);
}
