import '../entities/feed_item.dart';
import '../repositories/feed_repository.dart';

class GetFeedUseCase {
  final FeedRepository repository;

  const GetFeedUseCase(this.repository);

  Future<FeedPage> call({required int page}) {
    return repository.getFeed(page: page);
  }
}
