import '../repositories/interactions_repository.dart';

class UnlikeTrackUseCase {
  final InteractionsRepository repository;

  UnlikeTrackUseCase(this.repository);

  Future<void> call(String trackId) {
    return repository.unlikeTrack(trackId);
  }
}
