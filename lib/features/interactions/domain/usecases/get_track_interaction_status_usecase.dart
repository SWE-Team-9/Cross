import '../entities/interaction_status.dart';
import '../repositories/interactions_repository.dart';

class GetTrackInteractionStatusUseCase {
  final InteractionsRepository repository;

  GetTrackInteractionStatusUseCase(this.repository);

  Future<InteractionStatus> call(String trackId) {
    return repository.getTrackInteractionStatus(trackId);
  }
}
