// ─────────────────────────────────────────────────────────────────────────────
//  feed_repository.dart  —  Domain Repository (Abstract)
// ─────────────────────────────────────────────────────────────────────────────

import '../entities/feed_item.dart';

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

  /// POST /api/v1/player/tracks/{trackId}/play
  Future<void> recordPlay(String trackId);
}
