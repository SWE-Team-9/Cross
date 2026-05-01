import '../repositories/playlists_repository.dart';

class DeletePlaylistUseCase {
  final PlaylistsRepository repository;

  DeletePlaylistUseCase(this.repository);

  Future<void> call(String playlistId) {
    return repository.deletePlaylist(playlistId);
  }
}
