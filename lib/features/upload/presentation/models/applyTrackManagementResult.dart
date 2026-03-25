import '../../domain/entities/ManagedTrack.dart';
import 'trackManagementResult.dart';

List<ManagedTrack> applyTrackManagementResult({
  required List<ManagedTrack> tracks,
  required TrackManagementResult result,
}) {
  if (result is TrackUpdatedResult) {
    return tracks.map((track) {
      return track.id == result.track.id ? result.track : track;
    }).toList();
  }

  if (result is TrackDeletedResult) {
    return tracks.where((track) => track.id != result.trackId).toList();
  }

  return List<ManagedTrack>.from(tracks);
}
