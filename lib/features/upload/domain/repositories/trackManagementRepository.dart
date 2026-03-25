import '../entities/ManagedTrack.dart';
import '../entities/TrackManagementForm.dart';
import '../entities/TrackManagementVisibility.dart';

abstract class TrackManagementRepository {
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  });

  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  });

  Future<void> deleteTrack({
    required String trackId,
  });
}
