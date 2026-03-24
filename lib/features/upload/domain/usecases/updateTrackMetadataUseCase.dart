import '../entities/ManagedTrack.dart';
import '../entities/TrackManagementForm.dart';
import '../repositories/trackManagementRepository.dart';

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
