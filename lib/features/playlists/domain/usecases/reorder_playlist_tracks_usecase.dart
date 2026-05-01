import '../repositories/playlists_repository.dart';

class RecordPlaylistPlaybackUseCase {
  final PlaylistsRepository repository;

  RecordPlaylistPlaybackUseCase(this.repository);

  Future<void> call(String playlistId) {
    return repository.recordPlaylistPlayback(playlistId);
  }
}