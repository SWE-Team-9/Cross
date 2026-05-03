import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/home_content.dart';
import '../../domain/usecases/get_home_content_usecase.dart';
import '../../domain/usecases/get_home_trending_tracks_usecase.dart';
import 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit({
    required GetHomeContentUseCase getHomeContent,
    required GetHomeTrendingTracksUseCase getHomeTrendingTracks,
  })  : _getHomeContent = getHomeContent,
        _getHomeTrendingTracks = getHomeTrendingTracks,
        super(HomeState.initial());

  final GetHomeContentUseCase _getHomeContent;
  final GetHomeTrendingTracksUseCase _getHomeTrendingTracks;

  Future<void> load() async {
    emit(
      state.copyWith(
        isLoading: true,
        clearError: true,
        clearTrendingError: true,
      ),
    );

    try {
      final content = await _getHomeContent(
        selectedGenre: state.selectedGenre,
      );

      final safePlaylistGenre = _safePlaylistGenre(
        state.selectedPlaylistGenre,
        content.favoriteGenres,
      );

      emit(
        state.copyWith(
          isLoading: false,
          favoriteGenres: content.favoriteGenres,
          selectedGenre: content.selectedGenre,
          selectedPlaylistGenre: safePlaylistGenre,
          topPlaylists: content.topPlaylists,
          trendingTracks: content.trendingTracks,
          clearError: true,
          clearTrendingError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoading: false,
          errorMessage: 'Could not load home',
        ),
      );
    }
  }

  Future<void> refresh() async {
    emit(
      state.copyWith(
        isRefreshing: true,
        clearError: true,
        clearTrendingError: true,
      ),
    );

    try {
      final content = await _getHomeContent(
        selectedGenre: state.selectedGenre,
      );

      final safePlaylistGenre = _safePlaylistGenre(
        state.selectedPlaylistGenre,
        content.favoriteGenres,
      );

      emit(
        state.copyWith(
          isRefreshing: false,
          favoriteGenres: content.favoriteGenres,
          selectedGenre: content.selectedGenre,
          selectedPlaylistGenre: safePlaylistGenre,
          topPlaylists: content.topPlaylists,
          trendingTracks: content.trendingTracks,
          clearError: true,
          clearTrendingError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isRefreshing: false,
          errorMessage: 'Could not refresh home',
        ),
      );
    }
  }

  Future<void> selectGenre(String genre) async {
    if (genre == state.selectedGenre && state.trendingTracks.isNotEmpty) {
      return;
    }

    final safeGenre =
        genre.trim().isEmpty ? HomeContent.topLikedGenre : genre.trim();

    emit(
      state.copyWith(
        selectedGenre: safeGenre,
        isLoadingTrending: true,
        clearTrendingError: true,
      ),
    );

    try {
      final tracks = await _getHomeTrendingTracks(
        genre: safeGenre,
      );

      emit(
        state.copyWith(
          isLoadingTrending: false,
          trendingTracks: tracks,
          clearTrendingError: true,
        ),
      );
    } catch (_) {
      emit(
        state.copyWith(
          isLoadingTrending: false,
          trendingTracks: const [],
          trendingErrorMessage: 'Could not load tracks for this genre',
        ),
      );
    }
  }

  void selectPlaylistGenre(String genre) {
    final safeGenre = _safePlaylistGenre(
      genre,
      state.favoriteGenres,
    );

    if (safeGenre == state.selectedPlaylistGenre) {
      return;
    }

    emit(
      state.copyWith(
        selectedPlaylistGenre: safeGenre,
      ),
    );
  }

  String _safePlaylistGenre(String genre, List<String> favoriteGenres) {
    final cleanGenre = genre.trim();

    final options = <String>[
      HomeTopPlaylists.overall,
      ...favoriteGenres.where(
        (favoriteGenre) =>
            favoriteGenre.trim().isNotEmpty &&
            favoriteGenre.trim() != HomeContent.topLikedGenre,
      ),
    ];

    return options.contains(cleanGenre) ? cleanGenre : HomeTopPlaylists.overall;
  }
}