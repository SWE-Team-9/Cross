// ─────────────────────────────────────────────────────────────────────────────
//  toggle_like_usecase.dart  —  Use Case
//  Module 6: POST   /api/v1/interactions/tracks/{trackId}/like
//            DELETE /api/v1/interactions/tracks/{trackId}/like
// ─────────────────────────────────────────────────────────────────────────────

import '../repositories/feed_repository.dart';

class ToggleLikeUseCase {
  final FeedRepository repository;

  const ToggleLikeUseCase(this.repository);

  Future<({int likesCount, bool liked})> call({
    required String trackId,
    required bool currentlyLiked,
  }) {
    return repository.toggleLike(
      trackId: trackId,
      currentlyLiked: currentlyLiked,
    );
  }
}
