import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class HomeContent {
  static const String topLikedGenre = 'Top liked';

  final List<String> favoriteGenres;
  final String selectedGenre;
  final List<Track> trendingTracks;
  final List<PlaylistEntity> topPlaylists;

  const HomeContent({
    required this.favoriteGenres,
    required this.selectedGenre,
    required this.trendingTracks,
    required this.topPlaylists,
  });

  factory HomeContent.empty() {
    return const HomeContent(
      favoriteGenres: <String>[topLikedGenre],
      selectedGenre: topLikedGenre,
      trendingTracks: <Track>[],
      topPlaylists: <PlaylistEntity>[],
    );
  }
}
