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
    final playlists = dtos.map((dto) => dto.toEntity()).toList(growable: false);
    return _withEditableMetadata(playlists);
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
  }) async {
    final dto = await remoteDataSource.createPlaylist(
      title: title,
      description: description,
      visibility: visibility,
      initialTrackIds: initialTrackIds,
    );
    return dto.toEntity();
  }

  @override
  Future<PlaylistEntity> getPlaylistDetails(String playlistId) async {
    final dto = await remoteDataSource.getPlaylistDetails(playlistId);
    return dto.toEntity();
  }

  @override
  Future<PlaylistEntity> getPlaylistEditDetails(String playlistId) async {
    final dto = await remoteDataSource.getPlaylistEditDetails(playlistId);
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
  Future<String?> uploadPlaylistCover({
    required String playlistId,
    required String filePath,
  }) {
    return remoteDataSource.uploadPlaylistCover(
      playlistId: playlistId,
      filePath: filePath,
    );
  }

  @override
  Future<List<PlaylistEntity>> getRecentPlaylists({int limit = 10}) async {
    final dtos = await remoteDataSource.getRecentPlaylists(limit: limit);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<PlaylistEntity>> searchPublicPlaylists(
    String query, {
    int page = 1,
    int limit = 20,
  }) async {
    final dtos = await remoteDataSource.searchPublicPlaylists(
      query,
      page: page,
      limit: limit,
    );
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<void> likePlaylist(String playlistId) {
    return remoteDataSource.likePlaylist(playlistId);
  }

  @override
  Future<void> unlikePlaylist(String playlistId) {
    return remoteDataSource.unlikePlaylist(playlistId);
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

  Future<List<PlaylistEntity>> _withEditableMetadata(
    List<PlaylistEntity> playlists,
  ) async {
    if (playlists.isEmpty) return playlists;

    return Future.wait(
      playlists.map((playlist) async {
        if (playlist.coverImageUrl != null &&
            playlist.coverImageUrl!.trim().isNotEmpty) {
          return playlist;
        }

        try {
          final editDto = await remoteDataSource
              .getPlaylistEditDetails(playlist.playlistId);
          final edit = editDto.toEntity();
          return playlist.copyWith(
            title: edit.title,
            description: edit.description,
            visibility: edit.visibility,
            coverImageUrl: edit.coverImageUrl,
          );
        } catch (_) {
          return playlist;
        }
      }),
    );
  }
}
