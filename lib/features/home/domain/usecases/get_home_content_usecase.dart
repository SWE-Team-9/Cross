import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

import '../entities/home_content.dart';
import '../repositories/home_repository.dart';

class GetHomeContentUseCase {
  const GetHomeContentUseCase(this._repository);

  final HomeRepository _repository;

  Future<HomeContent> call({
    String selectedGenre = HomeContent.topLikedGenre,
    int playlistLimit = 10,
    int trackLimit = 5,
  }) async {
    final genres = await _getFavoriteGenres();
    final safeGenres = genres.isEmpty
        ? const <String>[HomeContent.topLikedGenre]
        : genres.toList(growable: false);
    final safeSelectedGenre =
        safeGenres.contains(selectedGenre) ? selectedGenre : safeGenres.first;

    final playlistsFuture = _getTopPlaylists(limit: playlistLimit);
    final tracksFuture = _getTrendingTracks(
      genre: safeSelectedGenre,
      limit: trackLimit,
    );

    return HomeContent(
      favoriteGenres: safeGenres,
      selectedGenre: safeSelectedGenre,
      topPlaylists: await playlistsFuture,
      trendingTracks: await tracksFuture,
    );
  }

  Future<List<String>> _getFavoriteGenres() async {
    try {
      return await _repository.getFavoriteGenres();
    } catch (_) {
      return const <String>[HomeContent.topLikedGenre];
    }
  }

  Future<List<PlaylistEntity>> _getTopPlaylists({required int limit}) async {
    try {
      return await _repository.getTopPlaylists(limit: limit);
    } catch (_) {
      return const <PlaylistEntity>[];
    }
  }

  Future<List<Track>> _getTrendingTracks({
    required String genre,
    required int limit,
  }) async {
    try {
      return await _repository.getTrendingTracks(
        genre: genre,
        limit: limit,
      );
    } catch (_) {
      return const <Track>[];
    }
  }
}
