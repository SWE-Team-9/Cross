import '../entities/ManagedTrack.dart';
import '../entities/TrackManagementVisibility.dart';
import '../repositories/trackManagementRepository.dart';

class UpdateTrackVisibilityUseCase {
  const UpdateTrackVisibilityUseCase(this._trackManagementRepository);

  final TrackManagementRepository _trackManagementRepository;

  Future<ManagedTrack> call({
    required String trackId,
    required TrackManagementVisibility visibility,
  }) {
    return _trackManagementRepository.updateTrackVisibility(
      trackId: trackId,
      visibility: visibility,
    );
  }
}
