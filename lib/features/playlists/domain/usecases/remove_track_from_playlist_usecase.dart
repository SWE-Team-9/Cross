import '../repositories/playlists_repository.dart';

class RemoveTrackFromPlaylistUseCase {
  final PlaylistsRepository repository;

  RemoveTrackFromPlaylistUseCase(this.repository);

  Future<void> call({
    required String playlistId,
    required String trackId,
  }) {
    return repository.removeTrackFromPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
  }
}
