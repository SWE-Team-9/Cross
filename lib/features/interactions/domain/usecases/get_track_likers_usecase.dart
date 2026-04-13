import '../entities/paginated_engagement_users.dart';
import '../repositories/interactions_repository.dart';

class GetTrackLikersUseCase {
  final InteractionsRepository repository;

  GetTrackLikersUseCase(this.repository);

  Future<PaginatedEngagementUsers> call(
    String trackId, {
    int page = 1,
    int limit = 20,
  }) {
    return repository.getTrackLikers(
      trackId,
      page: page,
      limit: limit,
    );
  }
}
