// ─────────────────────────────────────────────────────────────────────────────
//  toggle_repost_usecase.dart  —  Use Case
//  Module 6: POST   /api/v1/interactions/tracks/{trackId}/repost
//            DELETE /api/v1/interactions/tracks/{trackId}/repost
// ─────────────────────────────────────────────────────────────────────────────

import '../repositories/feed_repository.dart';

class ToggleRepostUseCase {
  final FeedRepository repository;

  const ToggleRepostUseCase(this.repository);

  Future<({int repostsCount, bool reposted})> call({
    required String trackId,
    required bool currentlyReposted,
  }) {
    return repository.toggleRepost(
      trackId: trackId,
      currentlyReposted: currentlyReposted,
    );
  }
}
