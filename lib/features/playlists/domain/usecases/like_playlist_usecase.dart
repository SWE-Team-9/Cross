import '../repositories/playlists_repository.dart';

class LikePlaylistUseCase {
  final PlaylistsRepository repository;

  LikePlaylistUseCase(this.repository);

  Future<void> call(String playlistId) {
    return repository.likePlaylist(playlistId);
  }
}
