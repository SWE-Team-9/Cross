import '../entities/managed_track.dart';
import '../entities/track_management_form.dart';
import '../repositories/track_management_repository.dart';

class UpdateTrackMetadataUseCase {
  const UpdateTrackMetadataUseCase(this._trackManagementRepository);

  final TrackManagementRepository _trackManagementRepository;

  Future<ManagedTrack> call({
    required String trackId,
    required TrackManagementForm form,
  }) {
    return _trackManagementRepository.updateTrackMetadata(
      trackId: trackId,
      form: form,
    );
  }
}
