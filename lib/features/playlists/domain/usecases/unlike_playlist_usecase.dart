import '../repositories/playlists_repository.dart';

class UnlikePlaylistUseCase {
  final PlaylistsRepository repository;

  UnlikePlaylistUseCase(this.repository);

  Future<void> call(String playlistId) {
    return repository.unlikePlaylist(playlistId);
  }
}
