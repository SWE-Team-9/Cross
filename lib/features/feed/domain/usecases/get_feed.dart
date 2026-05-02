// ─────────────────────────────────────────────────────────────────────────────
//  get_feed_usecase.dart  —  Use Case
//  Module 4: GET /api/v1/users/{userId}/tracks   (following)
//  Module 3: GET /api/v1/social/suggestions      (discover)
// ─────────────────────────────────────────────────────────────────────────────

import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

class GetFeedUseCase {
  final FeedRepository repository;

  const GetFeedUseCase(this.repository);

  Future<FeedPage> call({required String tab, required int page}) {
    return repository.getFeed(tab: tab, page: page);
  }
}
