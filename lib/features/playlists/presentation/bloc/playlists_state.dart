import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class PlaylistsState {
  final List<PlaylistEntity> playlists;
  final PlaylistEntity? selectedPlaylist;
  final bool isLoadingMyPlaylists;
  final bool isLoadingMoreMyPlaylists;
  final int myPlaylistsPage;
  final bool hasMoreMyPlaylists;
  final bool isLoadingDetails;
  final bool isLoadingMorePlaylistTracks;
  final int playlistTracksOffset;
  final bool hasMorePlaylistTracks;
  final bool isLoadingEditDetails;
  final bool isSubmitting;
  final bool isReordering;
  final String? embedCode;
  final String? errorMessage;
  final String? infoMessage;

  const PlaylistsState({
    required this.playlists,
    required this.selectedPlaylist,
    required this.isLoadingMyPlaylists,
    required this.isLoadingMoreMyPlaylists,
    required this.myPlaylistsPage,
    required this.hasMoreMyPlaylists,
    required this.isLoadingDetails,
    required this.isLoadingMorePlaylistTracks,
    required this.playlistTracksOffset,
    required this.hasMorePlaylistTracks,
    required this.isLoadingEditDetails,
    required this.isSubmitting,
    required this.isReordering,
    required this.embedCode,
    required this.errorMessage,
    required this.infoMessage,
  });

  factory PlaylistsState.initial() {
    return const PlaylistsState(
      playlists: <PlaylistEntity>[],
      selectedPlaylist: null,
      isLoadingMyPlaylists: false,
      isLoadingMoreMyPlaylists: false,
      myPlaylistsPage: 0,
      hasMoreMyPlaylists: true,
      isLoadingDetails: false,
      isLoadingMorePlaylistTracks: false,
      playlistTracksOffset: 0,
      hasMorePlaylistTracks: true,
      isLoadingEditDetails: false,
      isSubmitting: false,
      isReordering: false,
      embedCode: null,
      errorMessage: null,
      infoMessage: null,
    );
  }

  PlaylistsState copyWith({
    List<PlaylistEntity>? playlists,
    PlaylistEntity? selectedPlaylist,
    bool clearSelectedPlaylist = false,
    bool? isLoadingMyPlaylists,
    bool? isLoadingMoreMyPlaylists,
    int? myPlaylistsPage,
    bool? hasMoreMyPlaylists,
    bool? isLoadingDetails,
    bool? isLoadingMorePlaylistTracks,
    int? playlistTracksOffset,
    bool? hasMorePlaylistTracks,
    bool? isLoadingEditDetails,
    bool? isSubmitting,
    bool? isReordering,
    String? embedCode,
    bool clearEmbedCode = false,
    String? errorMessage,
    bool clearError = false,
    String? infoMessage,
    bool clearInfo = false,
  }) {
    return PlaylistsState(
      playlists: playlists ?? this.playlists,
      selectedPlaylist: clearSelectedPlaylist
          ? null
          : (selectedPlaylist ?? this.selectedPlaylist),
      isLoadingMyPlaylists: isLoadingMyPlaylists ?? this.isLoadingMyPlaylists,
      isLoadingMoreMyPlaylists:
          isLoadingMoreMyPlaylists ?? this.isLoadingMoreMyPlaylists,
      myPlaylistsPage: myPlaylistsPage ?? this.myPlaylistsPage,
      hasMoreMyPlaylists: hasMoreMyPlaylists ?? this.hasMoreMyPlaylists,
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isLoadingMorePlaylistTracks:
          isLoadingMorePlaylistTracks ?? this.isLoadingMorePlaylistTracks,
      playlistTracksOffset: playlistTracksOffset ?? this.playlistTracksOffset,
      hasMorePlaylistTracks:
          hasMorePlaylistTracks ?? this.hasMorePlaylistTracks,
      isLoadingEditDetails: isLoadingEditDetails ?? this.isLoadingEditDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isReordering: isReordering ?? this.isReordering,
      embedCode: clearEmbedCode ? null : (embedCode ?? this.embedCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
