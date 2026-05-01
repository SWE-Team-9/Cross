import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/add_track_to_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/create_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/delete_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_my_playlists_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_details_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_edit_details_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/get_playlist_embed_code_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/like_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/remove_track_from_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/reorder_playlist_tracks_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/resolve_secret_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/unlike_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/update_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/upload_playlist_cover_usecase.dart';

import 'playlists_state.dart';

class PlaylistsCubit extends Cubit<PlaylistsState> {
  final GetMyPlaylistsUseCase getMyPlaylistsUseCase;
  final CreatePlaylistUseCase createPlaylistUseCase;
  final GetPlaylistDetailsUseCase getPlaylistDetailsUseCase;
  final GetPlaylistEditDetailsUseCase? getPlaylistEditDetailsUseCase;
  final UpdatePlaylistUseCase updatePlaylistUseCase;
  final UploadPlaylistCoverUseCase? uploadPlaylistCoverUseCase;
  final DeletePlaylistUseCase deletePlaylistUseCase;
  final AddTrackToPlaylistUseCase addTrackToPlaylistUseCase;
  final RemoveTrackFromPlaylistUseCase removeTrackFromPlaylistUseCase;
  final ReorderPlaylistTracksUseCase reorderPlaylistTracksUseCase;
  final ResolveSecretPlaylistUseCase resolveSecretPlaylistUseCase;
  final GetPlaylistEmbedCodeUseCase getPlaylistEmbedCodeUseCase;
  final LikePlaylistUseCase? likePlaylistUseCase;
  final UnlikePlaylistUseCase? unlikePlaylistUseCase;

  PlaylistsCubit({
    required this.getMyPlaylistsUseCase,
    required this.createPlaylistUseCase,
    required this.getPlaylistDetailsUseCase,
    this.getPlaylistEditDetailsUseCase,
    required this.updatePlaylistUseCase,
    this.uploadPlaylistCoverUseCase,
    required this.deletePlaylistUseCase,
    required this.addTrackToPlaylistUseCase,
    required this.removeTrackFromPlaylistUseCase,
    required this.reorderPlaylistTracksUseCase,
    required this.resolveSecretPlaylistUseCase,
    required this.getPlaylistEmbedCodeUseCase,
    this.likePlaylistUseCase,
    this.unlikePlaylistUseCase,
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
    List<String> initialTrackIds = const <String>[],
    String? coverImagePath,
  }) async {
    if (state.isSubmitting) return null;

    if (_titleExists(title)) {
      emit(
        state.copyWith(
          errorMessage: 'A playlist with this name already exists',
          clearInfo: true,
        ),
      );
      return null;
    }

    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      var created = await createPlaylistUseCase(
        title: title,
        description: description,
        visibility: visibility,
        initialTrackIds: initialTrackIds,
      );

      if (coverImagePath != null && coverImagePath.trim().isNotEmpty) {
        final uploader = uploadPlaylistCoverUseCase;
        if (uploader != null) {
          final coverImageUrl = await uploader(
            playlistId: created.playlistId,
            filePath: coverImagePath.trim(),
          );
          created = created.copyWith(coverImageUrl: coverImageUrl);
        }
      }

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
    String? coverImagePath,
  }) async {
    if (state.isSubmitting) return;

    if (title != null && _titleExists(title, excludingPlaylistId: playlistId)) {
      emit(
        state.copyWith(
          errorMessage: 'A playlist with this name already exists',
          clearInfo: true,
        ),
      );
      return;
    }

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

      String? uploadedCoverUrl;
      if (coverImagePath != null && coverImagePath.trim().isNotEmpty) {
        final uploader = uploadPlaylistCoverUseCase;
        if (uploader != null) {
          uploadedCoverUrl = await uploader(
            playlistId: playlistId,
            filePath: coverImagePath.trim(),
          );
        }
      }

      final current = state.selectedPlaylist;
      PlaylistEntity? nextSelected = current;

      if (current != null && current.playlistId == playlistId) {
        nextSelected = current.copyWith(
          title: title,
          description: description,
          visibility: visibility,
          coverImageUrl: uploadedCoverUrl,
          clearSecretToken: visibility == PlaylistVisibility.publicPlaylist,
        );
      }

      final updatedList = state.playlists.map((playlist) {
        if (playlist.playlistId != playlistId) return playlist;
        return playlist.copyWith(
          title: title,
          description: description,
          visibility: visibility,
          coverImageUrl: uploadedCoverUrl,
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

  Future<PlaylistEntity?> loadPlaylistEditDetails(String playlistId) async {
    final loader = getPlaylistEditDetailsUseCase;
    if (loader == null) {
      return state.selectedPlaylist?.playlistId == playlistId
          ? state.selectedPlaylist
          : null;
    }

    emit(state.copyWith(isLoadingEditDetails: true, clearError: true));

    try {
      final playlist = await loader(playlistId);
      emit(
        state.copyWith(
          isLoadingEditDetails: false,
          selectedPlaylist: state.selectedPlaylist?.playlistId == playlistId
              ? state.selectedPlaylist?.copyWith(
                  title: playlist.title,
                  description: playlist.description,
                  visibility: playlist.visibility,
                  coverImageUrl: playlist.coverImageUrl,
                  isLiked: playlist.isLiked,
                )
              : state.selectedPlaylist,
          playlists: _upsertPlaylist(state.playlists, playlist),
          clearError: true,
        ),
      );
      return playlist;
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingEditDetails: false,
          errorMessage: e.toString(),
        ),
      );
      return null;
    }
  }

  Future<void> likePlaylist(String playlistId) async {
    final like = likePlaylistUseCase;
    if (like == null || state.isSubmitting) return;

    final previousSelected = state.selectedPlaylist;
    final previousPlaylists = state.playlists;
    emit(
      state.copyWith(
        isSubmitting: true,
        selectedPlaylist: _likedSelected(playlistId, true),
        playlists: _setPlaylistLiked(state.playlists, playlistId, true),
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await like(playlistId);
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Playlist liked',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          selectedPlaylist: previousSelected,
          playlists: previousPlaylists,
          errorMessage: e.toString(),
        ),
      );
    }
  }

  Future<void> unlikePlaylist(String playlistId) async {
    final unlike = unlikePlaylistUseCase;
    if (unlike == null || state.isSubmitting) return;

    final previousSelected = state.selectedPlaylist;
    final previousPlaylists = state.playlists;
    emit(
      state.copyWith(
        isSubmitting: true,
        selectedPlaylist: _likedSelected(playlistId, false),
        playlists: _setPlaylistLiked(state.playlists, playlistId, false),
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      await unlike(playlistId);
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Playlist unliked',
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isSubmitting: false,
          selectedPlaylist: previousSelected,
          playlists: previousPlaylists,
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

      final shouldDeletePlaylist = selected != null &&
          selected.playlistId == playlistId &&
          existingTracks != null &&
          existingTracks.length <= 1;

      if (shouldDeletePlaylist) {
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
        return;
      }

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

  PlaylistEntity? _likedSelected(String playlistId, bool isLiked) {
    final selected = state.selectedPlaylist;
    if (selected == null || selected.playlistId != playlistId) return selected;
    return selected.copyWith(isLiked: isLiked);
  }

  List<PlaylistEntity> _setPlaylistLiked(
    List<PlaylistEntity> playlists,
    String playlistId,
    bool isLiked,
  ) {
    return playlists.map((playlist) {
      if (playlist.playlistId != playlistId) return playlist;
      return playlist.copyWith(isLiked: isLiked);
    }).toList(growable: false);
  }

  bool _titleExists(String title, {String? excludingPlaylistId}) {
    final normalized = _normalizeTitle(title);
    if (normalized.isEmpty) return false;

    return state.playlists.any((playlist) {
      if (playlist.playlistId == excludingPlaylistId) return false;
      return _normalizeTitle(playlist.title) == normalized;
    });
  }

  String _normalizeTitle(String title) => title.trim().toLowerCase();
}
