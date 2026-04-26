import '../entities/playlist_entity.dart';

abstract class PlaylistsRepository {
  Future<List<PlaylistEntity>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  });

  Future<PlaylistEntity> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
  });

  Future<PlaylistEntity> getPlaylistDetails(String playlistId);

  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
  });

  Future<void> deletePlaylist(String playlistId);

  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  });

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  });

  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<String> orderedTrackIds,
  });

  Future<PlaylistEntity> resolveSecretPlaylist(String secretToken);

  Future<String> getPlaylistEmbedCode(String playlistId);
}
