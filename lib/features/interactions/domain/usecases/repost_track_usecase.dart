import '../repositories/interactions_repository.dart';

class RepostTrackUseCase {
  final InteractionsRepository repository;

  RepostTrackUseCase(this.repository);

  Future<void> call(String trackId) {
    return repository.repostTrack(trackId);
  }
}