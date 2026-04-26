import '../repositories/playlists_repository.dart';

class AddTrackToPlaylistUseCase {
  final PlaylistsRepository repository;

  AddTrackToPlaylistUseCase(this.repository);

  Future<void> call({
    required String playlistId,
    required String trackId,
  }) {
    return repository.addTrackToPlaylist(
      playlistId: playlistId,
      trackId: trackId,
    );
  }
}
