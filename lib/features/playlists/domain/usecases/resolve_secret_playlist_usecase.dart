import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class ResolveSecretPlaylistUseCase {
  final PlaylistsRepository repository;

  ResolveSecretPlaylistUseCase(this.repository);

  Future<PlaylistEntity> call(String secretToken) {
    return repository.resolveSecretPlaylist(secretToken);
  }
}
