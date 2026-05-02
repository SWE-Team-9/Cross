import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class GetTopPlaylistsUseCase {
  final PlaylistsRepository repository;

  GetTopPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call({
    int limit = 10,
  }) {
    return repository.getTopPlaylists(limit: limit);
  }
}
