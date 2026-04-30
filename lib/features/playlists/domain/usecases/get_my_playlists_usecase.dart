import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class GetMyPlaylistsUseCase {
  final PlaylistsRepository repository;

  GetMyPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call({
    int page = 1,
    int limit = 20,
  }) {
    return repository.getMyPlaylists(page: page, limit: limit);
  }
}
