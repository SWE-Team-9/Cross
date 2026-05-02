import '../repositories/interactions_repository.dart';

class UnrepostTrackUseCase {
  final InteractionsRepository repository;

  UnrepostTrackUseCase(this.repository);

  Future<void> call(String trackId) {
    return repository.unrepostTrack(trackId);
  }
}
