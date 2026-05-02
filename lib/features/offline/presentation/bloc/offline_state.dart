import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class OfflineState {
  final Map<String, String> downloadedTracks;
  final Map<String, Track> downloadedTrackDetails;
  final Map<String, PlaylistEntity> downloadedPlaylists;

  const OfflineState({
    this.downloadedTracks = const {},
    this.downloadedTrackDetails = const {},
    this.downloadedPlaylists = const {},
  });

  OfflineState copyWith({
    Map<String, String>? downloadedTracks,
    Map<String, Track>? downloadedTrackDetails,
    Map<String, PlaylistEntity>? downloadedPlaylists,
  }) {
    return OfflineState(
      downloadedTracks: downloadedTracks ?? this.downloadedTracks,
      downloadedTrackDetails:
          downloadedTrackDetails ?? this.downloadedTrackDetails,
      downloadedPlaylists: downloadedPlaylists ?? this.downloadedPlaylists,
    );
  }
}
