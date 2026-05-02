import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class GetPlaylistEditDetailsUseCase {
  final PlaylistsRepository repository;

  GetPlaylistEditDetailsUseCase(this.repository);

  Future<PlaylistEntity> call(String playlistId) {
    return repository.getPlaylistEditDetails(playlistId);
  }
}
