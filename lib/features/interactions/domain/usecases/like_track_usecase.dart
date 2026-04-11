import '../repositories/interactions_repository.dart';

class LikeTrackUseCase {
  final InteractionsRepository repository;

  LikeTrackUseCase(this.repository);

  Future<void> call(String trackId) {
    return repository.likeTrack(trackId);
  }
}