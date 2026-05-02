import '../repositories/playlists_repository.dart';

class GetPlaylistEmbedCodeUseCase {
  final PlaylistsRepository repository;

  GetPlaylistEmbedCodeUseCase(this.repository);

  Future<String> call(
    String playlistId, {
    String? theme,
    bool? autoplay,
    int? start,
    bool? hideArtwork,
    int? width,
    int? height,
  }) {
    return repository.getPlaylistEmbedCode(
      playlistId,
      theme: theme,
      autoplay: autoplay,
      start: start,
      hideArtwork: hideArtwork,
      width: width,
      height: height,
    );
  }
}
