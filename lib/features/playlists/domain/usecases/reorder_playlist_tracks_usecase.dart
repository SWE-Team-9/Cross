import '../repositories/playlists_repository.dart';

class ReorderPlaylistTracksUseCase {
  final PlaylistsRepository repository;

  ReorderPlaylistTracksUseCase(this.repository);

  Future<void> call({
    required String playlistId,
    required List<String> orderedTrackIds,
  }) {
    return repository.reorderPlaylistTracks(
      playlistId: playlistId,
      orderedTrackIds: orderedTrackIds,
    );
  }
}
