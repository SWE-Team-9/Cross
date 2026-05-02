import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class GetLikedPlaylistsUseCase {
  final PlaylistsRepository repository;

  GetLikedPlaylistsUseCase(this.repository);

  Future<List<PlaylistEntity>> call({
    int page = 1,
    int limit = 20,
  }) {
    return repository.getLikedPlaylists(page: page, limit: limit);
  }
}
