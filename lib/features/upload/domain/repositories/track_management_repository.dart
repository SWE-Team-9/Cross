import '../entities/managed_track.dart';
import '../entities/track_management_form.dart';
import '../entities/track_management_visibility.dart';

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
