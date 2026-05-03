import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class HomeTopPlaylistGroup {
  final String genre;
  final List<PlaylistEntity> playlists;

  const HomeTopPlaylistGroup({
    required this.genre,
    required this.playlists,
  });
}

class HomeTopPlaylists {
  static const String overall = 'Overall';

  final List<PlaylistEntity> overallPlaylists;
  final List<HomeTopPlaylistGroup> genreGroups;

  const HomeTopPlaylists({
    required this.overallPlaylists,
    required this.genreGroups,
  });

  factory HomeTopPlaylists.empty() {
    return const HomeTopPlaylists(
      overallPlaylists: <PlaylistEntity>[],
      genreGroups: <HomeTopPlaylistGroup>[],
    );
  }

  bool get isEmpty => overallPlaylists.isEmpty && genreGroups.isEmpty;

  bool get isNotEmpty => !isEmpty;

  List<String> get options {
    return <String>[
      if (overallPlaylists.isNotEmpty) overall,
      ...genreGroups
          .where((group) => group.playlists.isNotEmpty)
          .map((group) => group.genre),
    ];
  }

  List<PlaylistEntity> playlistsFor(String option) {
    if (option == overall) return overallPlaylists;

    for (final group in genreGroups) {
      if (group.genre == option) return group.playlists;
    }

    return overallPlaylists;
  }
}

class HomeContent {
  static const String topLikedGenre = 'Top liked';

  final List<String> favoriteGenres;
  final String selectedGenre;
  final List<Track> trendingTracks;
  final HomeTopPlaylists topPlaylists;

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
      topPlaylists: HomeTopPlaylists(
        overallPlaylists: <PlaylistEntity>[],
        genreGroups: <HomeTopPlaylistGroup>[],
      ),
    );
  }
}
