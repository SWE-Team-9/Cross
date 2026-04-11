import '../../domain/entities/interaction_status.dart';
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
}