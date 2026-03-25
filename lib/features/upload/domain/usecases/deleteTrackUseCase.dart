import '../repositories/trackManagementRepository.dart';

class DeleteTrackUseCase {
  const DeleteTrackUseCase(this._trackManagementRepository);

  final TrackManagementRepository _trackManagementRepository;

  Future<void> call({
    required String trackId,
  }) {
    return _trackManagementRepository.deleteTrack(
      trackId: trackId,
    );
  }
}
