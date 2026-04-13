import '../entities/paginated_engagement_users.dart';
import '../repositories/interactions_repository.dart';

class GetTrackRepostersUseCase {
  final InteractionsRepository repository;

  GetTrackRepostersUseCase(this.repository);

  Future<PaginatedEngagementUsers> call(
    String trackId, {
    int page = 1,
    int limit = 20,
  }) {
    return repository.getTrackReposters(
      trackId,
      page: page,
      limit: limit,
    );
  }
}