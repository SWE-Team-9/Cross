import '../entities/playlist_entity.dart';
import '../repositories/playlists_repository.dart';

class CreatePlaylistUseCase {
  final PlaylistsRepository repository;

  CreatePlaylistUseCase(this.repository);

  Future<PlaylistEntity> call({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
  }) {
    return repository.createPlaylist(
      title: title,
      description: description,
      visibility: visibility,
      initialTrackIds: initialTrackIds,
    );
  }
}
