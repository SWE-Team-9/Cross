import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class GetRecentPlaylistsUseCase {
  final PlaylistsRepository repository;

  GetRecentPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call({
    int limit = 10,
  }) {
    return repository.getRecentPlaylists(limit: limit);
  }
}
