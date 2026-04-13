import '../../../upload/domain/entities/managed_track.dart';
import '../repositories/interactions_repository.dart';

class GetMyLikedTracksUseCase {
  final InteractionsRepository repository;

  GetMyLikedTracksUseCase(this.repository);

  Future<List<ManagedTrack>> call() {
    return repository.getMyLikedTracks();
  }
}