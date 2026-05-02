import '../repositories/playlists_repository.dart';

class UploadPlaylistCoverUseCase {
  final PlaylistsRepository repository;

  UploadPlaylistCoverUseCase(this.repository);

  Future<String?> call({
    required String playlistId,
    required String filePath,
  }) {
    return repository.uploadPlaylistCover(
      playlistId: playlistId,
      filePath: filePath,
    );
  }
}
