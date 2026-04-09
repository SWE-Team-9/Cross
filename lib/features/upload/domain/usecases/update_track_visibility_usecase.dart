import '../entities/managed_track.dart';
import '../entities/track_management_visibility.dart';
import '../repositories/track_management_repository.dart';

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
