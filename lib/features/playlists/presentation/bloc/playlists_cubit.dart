import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/add_track_to_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/create_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/delete_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_my_playlists_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_details_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_embed_code_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/remove_track_from_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/reorder_playlist_tracks_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/resolve_secret_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/update_playlist_usecase.dart';

import 'playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  final GetMyPlaylistsUseCase getMyPlaylistsUseCase;
  final CreatePlaylistUseCase createPlaylistUseCase;
  final GetPlaylistDetailsUseCase getPlaylistDetailsUseCase;
  final UpdatePlaylistUseCase updatePlaylistUseCase;
  final DeletePlaylistUseCase deletePlaylistUseCase;
  final AddTrackToPlaylistUseCase addTrackToPlaylistUseCase;
  final RemoveTrackFromPlaylistUseCase removeTrackFromPlaylistUseCase;
  final ReorderPlaylistTracksUseCase reorderPlaylistTracksUseCase;
  final ResolveSecretPlaylistUseCase resolveSecretPlaylistUseCase;
  final GetPlaylistEmbedCodeUseCase getPlaylistEmbedCodeUseCase;

  PlaylistsCubit({
    required this.getMyPlaylistsUseCase,
    required this.createPlaylistUseCase,
    required this.getPlaylistDetailsUseCase,
    required this.updatePlaylistUseCase,
    required this.deletePlaylistUseCase,
    required this.addTrackToPlaylistUseCase,
    required this.removeTrackFromPlaylistUseCase,
    required this.reorderPlaylistTracksUseCase,
    required this.resolveSecretPlaylistUseCase,
    required this.getPlaylistEmbedCodeUseCase,
  }) : super(PlaylistsState.initial());

  Future<void> loadMyPlaylists({bool refresh = false}) async {
    if (state.isLoadingMyPlaylists && !refresh) return;

    emit(
      state.copyWith(
        isLoadingMyPlaylists: true,
        clearError: true,
      ),
    );

    try {
      final playlists = await getMyPlaylistsUseCase();
      emit(
        state.copyWith(
          playlists: playlists,
          isLoadingMyPlaylists: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMyPlaylists: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<PlaylistEntity?> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
  }) async {
    if (state.isSubmitting) return null;

    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      final created = await createPlaylistUseCase(
        title: title,
        description: description,
        visibility: visibility,
      );

      final nextPlaylists = <PlaylistEntity>[created, ...state.playlists];

      emit(
        state.copyWith(
          playlists: nextPlaylists,
          selectedPlaylist: created,
          isSubmitting: false,
          infoMessage: 'Playlist created',
          clearError: true,
        ),
      );

      return created;
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> loadPlaylistDetails(String playlistId) async {
    emit(
      state.copyWith(
        isLoadingDetails: true,
        clearError: true,
      ),
    );

    try {
      final playlist = await getPlaylistDetailsUseCase(playlistId);
      emit(
        state.copyWith(
          selectedPlaylist: playlist,
          playlists: _upsertPlaylist(state.playlists, playlist),
          isLoadingDetails: false,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingDetails: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
  }) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await updatePlaylistUseCase(
        playlistId: playlistId,
        title: title,
        description: description,
        visibility: visibility,
      );

      final current = state.selectedPlaylist;
      PlaylistEntity? nextSelected = current;

      if (current != null && current.playlistId == playlistId) {
        nextSelected = current.copyWith(
          title: title,
          description: description,
          visibility: visibility,
          clearSecretToken: visibility == PlaylistVisibility.publicPlaylist,
        );
      }

      final updatedList = state.playlists.map((playlist) {
        if (playlist.playlistId != playlistId) return playlist;
        return playlist.copyWith(
          title: title,
          description: description,
          visibility: visibility,
          clearSecretToken: visibility == PlaylistVisibility.publicPlaylist,
        );
      }).toList(growable: false);

      emit(
        state.copyWith(
          isSubmitting: false,
          playlists: updatedList,
          selectedPlaylist: nextSelected,
          infoMessage: 'Playlist updated',
          clearError: true,
        ),
      );

      if (nextSelected != null) {
        await loadPlaylistDetails(nextSelected.playlistId);
      }
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> deletePlaylist(String playlistId) async {
    if (state.isSubmitting) return;

    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await deletePlaylistUseCase(playlistId);

      final updated = state.playlists
          .where((playlist) => playlist.playlistId != playlistId)
          .toList(growable: false);

      emit(
        state.copyWith(
          isSubmitting: false,
          playlists: updated,
          clearSelectedPlaylist: true,
          infoMessage: 'Playlist deleted',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required Track track,
  }) async {
    if (state.isSubmitting) return false;

    emit(state.copyWith(isSubmitting: true, clearError: true, clearInfo: true));

    try {
      await addTrackToPlaylistUseCase(
        playlistId: playlistId,
        trackId: track.id,
      );

      final selected = state.selectedPlaylist;
      PlaylistEntity? updatedSelected = selected;
      if (selected != null && selected.playlistId == playlistId) {
        final alreadyExists =
            selected.tracks.any((item) => item.id == track.id);
        final nextTracks =
            alreadyExists ? selected.tracks : [...selected.tracks, track];
        updatedSelected = selected.copyWith(
          tracks: nextTracks,
          tracksCount:
              alreadyExists ? selected.tracksCount : selected.tracksCount + 1,
        );
      }

      final nextPlaylists = state.playlists.map((playlist) {
        if (playlist.playlistId != playlistId) return playlist;
        final alreadyExists =
            playlist.tracks.any((item) => item.id == track.id);
        final nextCount =
            alreadyExists ? playlist.tracksCount : playlist.tracksCount + 1;
        final nextTracks = playlist.tracks.isEmpty
            ? playlist.tracks
            : (alreadyExists ? playlist.tracks : [...playlist.tracks, track]);
        return playlist.copyWith(
          tracks: nextTracks,
          tracksCount: nextCount,
        );
      }).toList(growable: false);

      emit(
        state.copyWith(
          isSubmitting: false,
          playlists: nextPlaylists,
          selectedPlaylist: updatedSelected,
          infoMessage: 'Track added to playlist',
          clearError: true,
        ),
      );

      if (updatedSelected != null) {
        await loadPlaylistDetails(playlistId);
      }

      return true;
    } catch (e) {
      emit(state.copyWith(isSubmitting: false, errorMessage: e.toString()));
      return false;
    }
  }

  Future<void> removeTrackFromPlaylist({
    required String playlistId,
    required String trackId,
  }) async {
    if (state.isSubmitting) return;

    final selected = state.selectedPlaylist;
    final existingTracks = selected?.tracks;
    final existingCount = selected?.tracksCount ?? 0;

    if (selected != null && selected.playlistId == playlistId) {
      final optimisticTracks = selected.tracks
          .where((track) => track.id != trackId)
          .toList(growable: false);
      emit(
        state.copyWith(
          selectedPlaylist: selected.copyWith(
            tracks: optimisticTracks,
            tracksCount: optimisticTracks.length,
          ),
          isSubmitting: true,
          clearError: true,
          clearInfo: true,
        ),
      );
    } else {
      emit(state.copyWith(
          isSubmitting: true, clearError: true, clearInfo: true));
    }

    try {
      await removeTrackFromPlaylistUseCase(
        playlistId: playlistId,
        trackId: trackId,
      );

      final nextPlaylists = state.playlists.map((playlist) {
        if (playlist.playlistId != playlistId) return playlist;
        return playlist.copyWith(
          tracks: playlist.tracks
              .where((track) => track.id != trackId)
              .toList(growable: false),
          tracksCount: playlist.tracksCount > 0 ? playlist.tracksCount - 1 : 0,
        );
      }).toList(growable: false);

      emit(
        state.copyWith(
          isSubmitting: false,
          playlists: nextPlaylists,
          infoMessage: 'Track removed from playlist',
          clearError: true,
        ),
      );
    } catch (e) {
      PlaylistEntity? reverted = state.selectedPlaylist;
      if (reverted != null &&
          reverted.playlistId == playlistId &&
          existingTracks != null) {
        reverted = reverted.copyWith(
          tracks: existingTracks,
          tracksCount: existingCount,
        );
      }

      emit(
        state.copyWith(
          isSubmitting: false,
          selectedPlaylist: reverted,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> reorderTracks({
    required String playlistId,
    required List<Track> orderedTracks,
  }) async {
    final selected = state.selectedPlaylist;
    if (selected == null || selected.playlistId != playlistId) return;

    final previousTracks = selected.tracks;

    emit(
      state.copyWith(
        isReordering: true,
        selectedPlaylist: selected.copyWith(tracks: orderedTracks),
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await reorderPlaylistTracksUseCase(
        playlistId: playlistId,
        orderedTrackIds:
            orderedTracks.map((track) => track.id).toList(growable: false),
      );

      emit(
        state.copyWith(
          isReordering: false,
          infoMessage: 'Playlist reordered',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isReordering: false,
          selectedPlaylist: selected.copyWith(tracks: previousTracks),
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> resolveSecretPlaylist(String secretToken) async {
    emit(
      state.copyWith(
        isLoadingDetails: true,
        clearError: true,
      ),
    );

    try {
      final playlist = await resolveSecretPlaylistUseCase(secretToken);
      emit(
        state.copyWith(
          isLoadingDetails: false,
          selectedPlaylist: playlist,
          playlists: _upsertPlaylist(state.playlists, playlist),
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingDetails: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> loadEmbedCode(String playlistId) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      final embedCode = await getPlaylistEmbedCodeUseCase(playlistId);
      emit(
        state.copyWith(
          isSubmitting: false,
          embedCode: embedCode,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  void clearFeedback() {
    emit(
      state.copyWith(
        clearError: true,
        clearInfo: true,
      ),
    );
  }

  List<PlaylistEntity> _upsertPlaylist(
    List<PlaylistEntity> source,
    PlaylistEntity playlist,
  ) {
    final index =
        source.indexWhere((item) => item.playlistId == playlist.playlistId);
    if (index == -1) {
      return <PlaylistEntity>[playlist, ...source];
    }

    final next = source.toList(growable: false);
    next[index] = playlist;
    return next;
  }
}
