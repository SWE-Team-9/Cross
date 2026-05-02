import '../../domain/entities/managed_track.dart';

sealed class TrackManagementResult {
  const TrackManagementResult();
}

class TrackUpdatedResult extends TrackManagementResult {
  const TrackUpdatedResult(this.track);

  final ManagedTrack track;
}

class TrackDeletedResult extends TrackManagementResult {
  const TrackDeletedResult(this.trackId);

  final String trackId;
}
