import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

abstract class HomeRepository {
  Future<List<String>> getFavoriteGenres();

  Future<List<PlaylistEntity>> getTopPlaylists({int limit = 10});

  Future<List<Track>> getTrendingTracks({
    required String genre,
    int limit = 5,
  });
}
