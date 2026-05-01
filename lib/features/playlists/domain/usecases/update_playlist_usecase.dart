import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class UpdatePlaylistUseCase {
  final PlaylistsRepository repository;

  UpdatePlaylistUseCase(this.repository);

  Future<void> call({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
    String? genre,
  }) {
    return repository.updatePlaylist(
      playlistId: playlistId,
      title: title,
      description: description,
      visibility: visibility,
      genre: genre,
    );
  }
}
