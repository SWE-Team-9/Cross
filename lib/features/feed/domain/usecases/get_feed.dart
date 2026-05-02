// ─────────────────────────────────────────────────────────────────────────────
//  get_feed.dart  —  Use Cases
//  GET /api/v1/feed                  (activity feed)
//  GET /api/v1/discovery/search      (global search)
//  GET /api/v1/discovery/trending    (trending charts)
//  GET /api/v1/discovery/resolve     (permalink resolver)
// ─────────────────────────────────────────────────────────────────────────────

import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

// ─── Get Activity Feed ────────────────────────────────────────────────────────

class GetFeedUseCase {
  final FeedRepository repository;
  const GetFeedUseCase(this.repository);

  Future<FeedPage> call({required int page}) {
    return repository.getFeed(page: page);
  }
}

// ─── Search ───────────────────────────────────────────────────────────────────

class SearchUseCase {
  final FeedRepository repository;
  const SearchUseCase(this.repository);

  Future<SearchResults> call({required String query, int page = 1}) {
    return repository.search(query: query, page: page);
  }
}

// ─── Trending ─────────────────────────────────────────────────────────────────

class GetTrendingUseCase {
  final FeedRepository repository;
  const GetTrendingUseCase(this.repository);

  Future<List<TrendingTrack>> call() {
    return repository.getTrending();
  }
}

// ─── Resolve Permalink ────────────────────────────────────────────────────────

class ResolvePermalinkUseCase {
  final FeedRepository repository;
  const ResolvePermalinkUseCase(this.repository);

  Future<ResolveResult> call(String permalink) {
    return repository.resolve(permalink);
  }
}
