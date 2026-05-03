import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/home/domain/entities/home_content.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class HomeState {
  final bool isLoading;
  final bool isRefreshing;
  final bool isLoadingTrending;
  final List<String> favoriteGenres;
  final String selectedGenre;
  final List<Track> trendingTracks;
  final HomeTopPlaylists topPlaylists;
  final String? errorMessage;
  final String? trendingErrorMessage;
  final String selectedPlaylistGenre;
  const HomeState({
    required this.isLoading,
    required this.isRefreshing,
    required this.isLoadingTrending,
    required this.favoriteGenres,
    required this.selectedGenre,
    required this.selectedPlaylistGenre,
    required this.trendingTracks,
    required this.topPlaylists,
    required this.errorMessage,
    required this.trendingErrorMessage,
  });

  factory HomeState.initial() {
    return const HomeState(
      isLoading: false,
      isRefreshing: false,
      isLoadingTrending: false,
      favoriteGenres: <String>[HomeContent.topLikedGenre],
      selectedGenre: HomeContent.topLikedGenre,
      trendingTracks: <Track>[],
      topPlaylists: HomeTopPlaylists(
        overallPlaylists: <PlaylistEntity>[],
        genreGroups: <HomeTopPlaylistGroup>[],
      ),
      errorMessage: null,
      trendingErrorMessage: null,
      selectedPlaylistGenre: HomeTopPlaylists.overall,
    );
  }

  bool get hasContent => trendingTracks.isNotEmpty || topPlaylists.isNotEmpty;
  List<String> get playlistGenreOptions {
    return <String>[
      HomeTopPlaylists.overall,
      ...favoriteGenres.where(
        (genre) =>
            genre.trim().isNotEmpty &&
            genre.trim() != HomeContent.topLikedGenre,
      ),
    ];
  }

  List<PlaylistEntity> get selectedTopPlaylists {
    return topPlaylists.playlistsFor(selectedPlaylistGenre);
  }

  HomeState copyWith({
    bool? isLoading,
    bool? isRefreshing,
    bool? isLoadingTrending,
    List<String>? favoriteGenres,
    String? selectedGenre,
    String? selectedPlaylistGenre,
    List<Track>? trendingTracks,
    HomeTopPlaylists? topPlaylists,
    String? errorMessage,
    String? trendingErrorMessage,
    bool clearError = false,
    bool clearTrendingError = false,
  }) {
    return HomeState(
      isLoading: isLoading ?? this.isLoading,
      isRefreshing: isRefreshing ?? this.isRefreshing,
      isLoadingTrending: isLoadingTrending ?? this.isLoadingTrending,
      favoriteGenres: favoriteGenres ?? this.favoriteGenres,
      selectedGenre: selectedGenre ?? this.selectedGenre,
      selectedPlaylistGenre:
          selectedPlaylistGenre ?? this.selectedPlaylistGenre,
      trendingTracks: trendingTracks ?? this.trendingTracks,
      topPlaylists: topPlaylists ?? this.topPlaylists,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      trendingErrorMessage: clearTrendingError
          ? null
          : (trendingErrorMessage ?? this.trendingErrorMessage),
    );
  }
}
