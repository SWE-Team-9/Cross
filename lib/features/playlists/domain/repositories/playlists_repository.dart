import '../entities/playlist_entity.dart';

abstract class PlaylistsRepository {
  Future<List<PlaylistEntity>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  });

  Future<List<PlaylistEntity>> getRecentPlaylists({
    int limit = 10,
  });

  Future<List<PlaylistEntity>> getTopPlaylists({
    int limit = 10,
  });

  Future<PlaylistEntity> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
    String? genre,
  });

  Future<PlaylistEntity> getPlaylistDetails(
    String playlistId, {
    int? limit,
    int? offset,
  });

  Future<PlaylistEntity> getPlaylistEditDetails(String playlistId);

  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
    String? genre,
    String? playlistType,
    DateTime? releaseDate,
    List<String>? tags,
  });
  Future<String?> uploadPlaylistCover({
    required String playlistId,
    required String filePath,
  });

  Future<void> deletePlaylist(String playlistId);

  Future<List<PlaylistEntity>> getLikedPlaylists({
    int page = 1,
    int limit = 20,
  });

  Future<List<PlaylistEntity>> searchPublicPlaylists(
    String query, {
    int page = 1,
    int limit = 20,
  });

  Future<void> likePlaylist(String playlistId);

  Future<void> unlikePlaylist(String playlistId);

  Future<void> recordPlaylistPlayback(String playlistId);

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

  Future<String> getPlaylistEmbedCode(
    String playlistId, {
    String? theme,
    bool? autoplay,
    int? start,
    bool? hideArtwork,
    int? width,
    int? height,
  });
}
