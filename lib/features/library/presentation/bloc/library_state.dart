import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class LibraryState {
  final bool isLoadingRecentPlaylists;
  final bool isLoadingLikedPlaylists;
  final List<PlaylistEntity> recentPlaylists;
  final List<PlaylistEntity> likedPlaylists;
  final String? errorMessage;

  const LibraryState({
    required this.isLoadingRecentPlaylists,
    required this.isLoadingLikedPlaylists,
    required this.recentPlaylists,
    required this.likedPlaylists,
    required this.errorMessage,
  });

  factory LibraryState.initial() {
    return const LibraryState(
      isLoadingRecentPlaylists: false,
      isLoadingLikedPlaylists: false,
      recentPlaylists: <PlaylistEntity>[],
      likedPlaylists: <PlaylistEntity>[],
      errorMessage: null,
    );
  }

  LibraryState copyWith({
    bool? isLoadingRecentPlaylists,
    bool? isLoadingLikedPlaylists,
    List<PlaylistEntity>? recentPlaylists,
    List<PlaylistEntity>? likedPlaylists,
    String? errorMessage,
    bool clearError = false,
  }) {
    return LibraryState(
      isLoadingRecentPlaylists:
          isLoadingRecentPlaylists ?? this.isLoadingRecentPlaylists,
      isLoadingLikedPlaylists:
          isLoadingLikedPlaylists ?? this.isLoadingLikedPlaylists,
      recentPlaylists: recentPlaylists ?? this.recentPlaylists,
      likedPlaylists: likedPlaylists ?? this.likedPlaylists,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}
