import '../repositories/playlists_repository.dart';

class GetPlaylistEmbedCodeUseCase {
  final PlaylistsRepository repository;

  GetPlaylistEmbedCodeUseCase(this.repository);

  Future<String> call(String playlistId) {
    return repository.getPlaylistEmbedCode(playlistId);
  }
}
