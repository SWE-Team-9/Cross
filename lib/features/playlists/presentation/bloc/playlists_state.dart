import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

class PlaylistsState {
  final List<PlaylistEntity> playlists;
  final PlaylistEntity? selectedPlaylist;
  final bool isLoadingMyPlaylists;
  final bool isLoadingDetails;
  final bool isSubmitting;
  final bool isReordering;
  final String? embedCode;
  final String? errorMessage;
  final String? infoMessage;

  const PlaylistsState({
    required this.playlists,
    required this.selectedPlaylist,
    required this.isLoadingMyPlaylists,
    required this.isLoadingDetails,
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
      isLoadingDetails: false,
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
    bool? isLoadingDetails,
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
      isLoadingDetails: isLoadingDetails ?? this.isLoadingDetails,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      isReordering: isReordering ?? this.isReordering,
      embedCode: clearEmbedCode ? null : (embedCode ?? this.embedCode),
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      infoMessage: clearInfo ? null : (infoMessage ?? this.infoMessage),
    );
  }
}
