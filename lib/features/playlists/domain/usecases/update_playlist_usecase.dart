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
    int? genreId,
    String? playlistType,
    DateTime? releaseDate,
    List<String>? tags,
  }) {
    return repository.updatePlaylist(
      playlistId: playlistId,
      title: title,
      description: description,
      visibility: visibility,
      genreId: genreId,
      playlistType: playlistType,
      releaseDate: releaseDate,
      tags: tags,
    );
  }
}
