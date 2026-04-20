import '../../../upload/domain/entities/managed_track.dart';
import '../../domain/entities/interaction_status.dart';
import '../../domain/entities/paginated_engagement_users.dart';
import '../../domain/repositories/interactions_repository.dart';
import '../datasources/interactions_remote_data_source.dart';

class InteractionsRepositoryImpl implements InteractionsRepository {
  final InteractionsRemoteDataSource remoteDataSource;

  InteractionsRepositoryImpl(this.remoteDataSource);

  @override
  Future<void> likeTrack(String trackId) {
    return remoteDataSource.likeTrack(trackId);
  }

  @override
  Future<void> unlikeTrack(String trackId) {
    return remoteDataSource.unlikeTrack(trackId);
  }

  @override
  Future<void> repostTrack(String trackId) {
    return remoteDataSource.repostTrack(trackId);
  }

  @override
  Future<void> unrepostTrack(String trackId) {
    return remoteDataSource.unrepostTrack(trackId);
  }

  @override
  Future<InteractionStatus> getTrackInteractionStatus(String trackId) async {
    final dto = await remoteDataSource.getTrackInteractionStatus(trackId);
    return dto.toEntity();
  }

  @override
  Future<PaginatedEngagementUsers> getTrackLikers(
    String trackId, {
    int page = 1,
    int limit = 20,
  }) async {
    final dto = await remoteDataSource.getTrackLikers(
      trackId,
      page: page,
      limit: limit,
    );
    return dto.toEntity();
  }

  @override
  Future<PaginatedEngagementUsers> getTrackReposters(
    String trackId, {
    int page = 1,
    int limit = 20,
  }) async {
    final dto = await remoteDataSource.getTrackReposters(
      trackId,
      page: page,
      limit: limit,
    );
    return dto.toEntity();
  }

  @override
  Future<List<ManagedTrack>> getMyLikedTracks() async {
    final dtos = await remoteDataSource.getMyLikedTracks();
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<ManagedTrack>> getMyRepostedTracks() async {
    final dtos = await remoteDataSource.getMyRepostedTracks();
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }
}
