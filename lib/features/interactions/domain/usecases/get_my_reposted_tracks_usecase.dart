import '../../../upload/domain/entities/managed_track.dart';
import '../repositories/interactions_repository.dart';

class GetMyRepostedTracksUseCase {
  final InteractionsRepository repository;

  GetMyRepostedTracksUseCase(this.repository);

  Future<List<ManagedTrack>> call() {
    return repository.getMyRepostedTracks();
  }
}
