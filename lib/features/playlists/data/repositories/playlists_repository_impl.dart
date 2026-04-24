import 'package:soundcloud_clone/features/playlists/data/datasources/playlists_remote_data_source.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/repositories/playlists_repository.dart';

class PlaylistsRepositoryImpl implements PlaylistsRepository {
  final PlaylistsRemoteDataSource remoteDataSource;

  PlaylistsRepositoryImpl(this.remoteDataSource);

  @override
  Future<List<PlaylistEntity>> getMyPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    final dtos =
        await remoteDataSource.getMyPlaylists(page: page, limit: limit);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
  }) async {
    final dto = await remoteDataSource.createPlaylist(
      title: title,
      description: description,
      visibility: visibility,
    );
    return dto.toEntity();
  }

  @override
  Future<PlaylistEntity> getPlaylistDetails(String playlistId) async {
    final dto = await remoteDataSource.getPlaylistDetails(playlistId);
    return dto.toEntity();
  }

  @override
  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
  }) {
    return remoteDataSource.updatePlaylist(
      playlistId: playlistId,
      title: title,
      description: description,
      visibility: visibility,
    );
  }

  @override
  Future<void> deletePlaylist(String playlistId) {
    return remoteDataSource.deletePlaylist(playlistId);
  }

  @override
  Future<void> addTrackToPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    return remoteDataSource.addTrackToPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
  }

  @override
  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) {
    return remoteDataSource.removeTrackFromPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
  }

  @override
  Future<void> reorderPlaylistTracks({
    required String playlistId,
    required List<String> orderedTrackIds,
  }) {
    return remoteDataSource.reorderPlaylistTracks(
      playlistId: playlistId,
      orderedTrackIds: orderedTrackIds,
    );
  }

  @override
  Future<PlaylistEntity> resolveSecretPlaylist(String secretToken) async {
    final dto = await remoteDataSource.resolveSecretPlaylist(secretToken);
    return dto.toEntity();
  }

  @override
  Future<String> getPlaylistEmbedCode(String playlistId) {
    return remoteDataSource.getPlaylistEmbedCode(playlistId);
  }
}
