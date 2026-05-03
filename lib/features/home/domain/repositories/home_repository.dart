import 'package:soundcloud_clone/core/models/track.dart';

import '../entities/home_content.dart';

abstract class HomeRepository {
  Future<List<String>> getFavoriteGenres();

  Future<HomeTopPlaylists> getTopPlaylists({int limit = 10});

  Future<List<Track>> getTrendingTracks({
    required String genre,
    int limit = 5,
  });
}
