import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class GetPlaylistDetailsUseCase {
  final PlaylistsRepository repository;

  GetPlaylistDetailsUseCase(this.repository);

  Future<PlaylistEntity> call(
    String playlistId, {
    int? limit,
    int? offset,
  }) {
    return repository.getPlaylistDetails(
      playlistId,
      limit: limit,
      offset: offset,
    );
  }
}
