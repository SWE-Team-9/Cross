// features/playlist/data/repositories/playlist_repository_mock.dart
//
// TODO: Replace with real API calls when backend is ready.
// Backend will need endpoints like:
//   GET    /api/v1/playlists          (get user playlists)
//   POST   /api/v1/playlists          (create playlist)
//   POST   /api/v1/playlists/{id}/tracks  (add track)
//   DELETE /api/v1/playlists/{id}/tracks/{trackId}

import 'package:soundcloud_clone/core/models/track.dart';

class PlaylistModel {
  final String id;
  final String name;
  final List<Track> tracks;

  const PlaylistModel({
    required this.id,
    required this.name,
    required this.tracks,
  });

  PlaylistModel copyWith({String? name, List<Track>? tracks}) {
    return PlaylistModel(
      id: id,
      name: name ?? this.name,
      tracks: tracks ?? this.tracks,
    );
  }
}

class PlaylistRepository {
  // Singleton so any widget can access the same instance via getIt
  PlaylistRepository._();
  static final PlaylistRepository instance = PlaylistRepository._();

  // In-memory store — survives the session, gone on restart
  final List<PlaylistModel> _playlists = [
    PlaylistModel(id: 'pl_1', name: 'My Favourites', tracks: []),
    PlaylistModel(id: 'pl_2', name: 'Chill Vibes', tracks: []),
    PlaylistModel(id: 'pl_3', name: 'Workout Mix', tracks: []),
  ];

  List<PlaylistModel> getAll() => List.unmodifiable(_playlists);

  // TODO: POST /api/v1/playlists
  PlaylistModel createPlaylist(String name) {
    final playlist = PlaylistModel(
      id: 'pl_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      tracks: [],
    );
    _playlists.add(playlist);
    return playlist;
  }

  // TODO: POST /api/v1/playlists/{id}/tracks
  bool addTrack(String playlistId, Track track) {
    final index = _playlists.indexWhere((p) => p.id == playlistId);
    if (index == -1) return false;

    final playlist = _playlists[index];

    // Don't add duplicates
    if (playlist.tracks.any((t) => t.id == track.id)) return false;

    _playlists[index] = playlist.copyWith(
      tracks: [...playlist.tracks, track],
    );
    return true;
  }

  bool containsTrack(String playlistId, String trackId) {
    final playlist = _playlists.firstWhere(
      (p) => p.id == playlistId,
      orElse: () => const PlaylistModel(id: '', name: '', tracks: []),
    );
    return playlist.tracks.any((t) => t.id == trackId);
  }
}
