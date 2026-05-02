import 'package:soundcloud_clone/features/playlists/data/datasources/playlists_remote_data_source.dart';
import 'package:soundcloud_clone/features/playlists/data/local/liked_playlists_store.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/repositories/playlists_repository.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_genre.dart';

class PlaylistsRepositoryImpl implements PlaylistsRepository {
  final LikedPlaylistsStore likedPlaylistsStore;
  final PlaylistsRemoteDataSource remoteDataSource;

  PlaylistsRepositoryImpl(
    this.remoteDataSource, {
    this.likedPlaylistsStore = const LikedPlaylistsStore(),
  });

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
  Future<List<PlaylistEntity>> getRecentPlaylists({
    int limit = 10,
  }) async {
    final dtos = await remoteDataSource.getRecentPlaylists(limit: limit);
    return dtos.map((dto) => dto.toEntity()).toList(growable: false);
  }

  @override
  Future<List<PlaylistEntity>> getTopPlaylists({
    int limit = 10,
  }) async {
    final dtos = await remoteDataSource.getTopPlaylists(limit: limit);
    final playlists = dtos.map((dto) => dto.toEntity()).toList(growable: false);
    return _withEditableMetadata(playlists);
  }

  @override
  Future<PlaylistEntity> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
    String? genre,
  }) async {
    final dto = await remoteDataSource.createPlaylist(
      title: title,
      description: description,
      visibility: visibility,
      initialTrackIds: initialTrackIds,
      genre: genre,
    );
    return dto.toEntity().copyWith(
          genre: genre,
          clearGenre: genre == null || genre.trim().isEmpty,
          genreId: playlistGenreId(genre),
          clearGenreId: genre == null || genre.trim().isEmpty,
        );
  }

  @override
  Future<PlaylistEntity> getPlaylistDetails(
    String playlistId, {
    int? limit,
    int? offset,
  }) async {
    final dto = await remoteDataSource.getPlaylistDetails(
      playlistId,
      limit: limit,
      offset: offset,
    );
    final playlist = await _withEditableMetadataFor(dto.toEntity());
    final liked = await likedPlaylistsStore.isLiked(playlist.playlistId);
    return liked
        ? playlist.copyWith(
            isLiked: true,
            likesCount: playlist.isLiked
                ? playlist.likesCount
                : playlist.likesCount + 1,
          )
        : playlist;
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
    String? genre,
    String? playlistType,
    DateTime? releaseDate,
    List<String>? tags,
  }) {
    return remoteDataSource.updatePlaylist(
      playlistId: playlistId,
      title: title,
      description: description,
      visibility: visibility,
      genre: genre,
      playlistType: playlistType,
      releaseDate: releaseDate,
      tags: tags,
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
  Future<void> deletePlaylist(String playlistId) {
    return remoteDataSource.deletePlaylist(playlistId);
  }

  @override
  Future<List<PlaylistEntity>> getLikedPlaylists({
    int page = 1,
    int limit = 20,
  }) async {
    var remote = const <PlaylistEntity>[];
    try {
      final dtos =
          await remoteDataSource.getLikedPlaylists(page: page, limit: limit);
      remote = dtos
          .map((dto) => dto.toEntity().copyWith(isLiked: true))
          .toList(growable: false);
    } catch (_) {
      remote = const <PlaylistEntity>[];
    }

    final local = await likedPlaylistsStore.load(limit: limit);
    return _mergeLikedPlaylists(remote, local)
        .take(limit)
        .toList(growable: false);
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
  Future<void> recordPlaylistPlayback(String playlistId) {
    return remoteDataSource.recordPlaylistPlayback(playlistId);
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
  Future<String> getPlaylistEmbedCode(
    String playlistId, {
    String? theme,
    bool? autoplay,
    int? start,
    bool? hideArtwork,
    int? width,
    int? height,
  }) {
    return remoteDataSource.getPlaylistEmbedCode(
      playlistId,
      theme: theme,
      autoplay: autoplay,
      start: start,
      hideArtwork: hideArtwork,
      width: width,
      height: height,
    );
  }

  Future<List<PlaylistEntity>> _withEditableMetadata(
    List<PlaylistEntity> playlists,
  ) async {
    if (playlists.isEmpty) return playlists;

    return Future.wait(
      playlists.map((playlist) async {
        return _withEditableMetadataFor(playlist);
      }),
    );
  }

  Future<PlaylistEntity> _withEditableMetadataFor(
    PlaylistEntity playlist,
  ) async {
    final needsMetadata = playlist.coverImageUrl == null ||
        playlist.coverImageUrl!.trim().isEmpty ||
        playlist.genre == null ||
        playlist.releaseDate == null ||
        playlist.tags.isEmpty;

    if (!needsMetadata) return playlist;

    try {
      final editDto = await remoteDataSource.getPlaylistEditDetails(
        playlist.playlistId,
      );
      final edit = editDto.toEntity();
      return playlist.copyWith(
        title: edit.title,
        description: edit.description,
        visibility: edit.visibility,
        genre: edit.genre,
        genreId: edit.genreId,
        slug: edit.slug,
        playlistType: edit.playlistType,
        releaseDate: edit.releaseDate,
        tags: edit.tags,
        coverImageUrl: edit.coverImageUrl,
        likesCount: edit.likesCount,
        isLiked: edit.isLiked,
      );
    } catch (_) {
      return playlist;
    }
  }

  List<PlaylistEntity> _mergeLikedPlaylists(
    List<PlaylistEntity> remote,
    List<PlaylistEntity> local,
  ) {
    final merged = <PlaylistEntity>[];
    final seenIds = <String>{};

    for (final playlist in [...remote, ...local]) {
      if (playlist.playlistId.isEmpty || !seenIds.add(playlist.playlistId)) {
        continue;
      }
      merged.add(playlist.copyWith(isLiked: true));
    }

    return merged;
  }
}
