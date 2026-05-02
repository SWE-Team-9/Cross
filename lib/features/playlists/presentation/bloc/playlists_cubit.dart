import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/data/local/liked_playlists_store.dart';
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
import 'package:soundcloud_clone/features/playlists/domain/usecases/record_playlist_playback_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/resolve_secret_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/unlike_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/update_playlist_usecase.dart';
import 'package:soundcloud_clone/features/playlists/domain/usecases/upload_playlist_cover_usecase.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/track_genre.dart';

import 'playlists_state.dart';

const int _kPlaylistTitleMaxLength = 100;
const int _kPlaylistDescriptionMaxLength = 500;
const int _kMyPlaylistsPageSize = 20;

class PlaylistsCubit extends Cubit<PlaylistsState> {
  static const _likedPlaylistsStore = LikedPlaylistsStore();

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
  final RecordPlaylistPlaybackUseCase? recordPlaylistPlaybackUseCase;
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
    this.recordPlaylistPlaybackUseCase,
  }) : super(PlaylistsState.initial());
  Future<void> loadMyPlaylists({bool refresh = false}) async {
    if (state.isLoadingMyPlaylists || state.isLoadingMoreMyPlaylists) return;

    emit(
      state.copyWith(
        isLoadingMyPlaylists: true,
        isLoadingMoreMyPlaylists: false,
        myPlaylistsPage: refresh ? 0 : state.myPlaylistsPage,
        hasMoreMyPlaylists: true,
        clearError: true,
      ),
    );

    try {
      final playlists = await getMyPlaylistsUseCase(
        page: 1,
        limit: _kMyPlaylistsPageSize,
      );

      emit(
        state.copyWith(
          playlists: playlists,
          isLoadingMyPlaylists: false,
          myPlaylistsPage: 1,
          hasMoreMyPlaylists: playlists.length == _kMyPlaylistsPageSize,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMyPlaylists: false,
          isLoadingMoreMyPlaylists: false,
          errorMessage: _playlistErrorMessage(e),
        ),
      );
    }
  }

  Future<void> loadMoreMyPlaylists() async {
    if (state.isLoadingMyPlaylists ||
        state.isLoadingMoreMyPlaylists ||
        !state.hasMoreMyPlaylists) {
      return;
    }

    final nextPage = state.myPlaylistsPage <= 0 ? 1 : state.myPlaylistsPage + 1;

    emit(
      state.copyWith(
        isLoadingMoreMyPlaylists: true,
        clearError: true,
      ),
    );

    try {
      final nextPlaylists = await getMyPlaylistsUseCase(
        page: nextPage,
        limit: _kMyPlaylistsPageSize,
      );

      emit(
        state.copyWith(
          playlists: _appendUniquePlaylists(state.playlists, nextPlaylists),
          isLoadingMoreMyPlaylists: false,
          myPlaylistsPage: nextPage,
          hasMoreMyPlaylists: nextPlaylists.length == _kMyPlaylistsPageSize,
          clearError: true,
        ),
      );
    } catch (e) {
      emit(
        state.copyWith(
          isLoadingMoreMyPlaylists: false,
          errorMessage: _playlistErrorMessage(e),
        ),
      );
    }
  }

  Future<PlaylistEntity?> createPlaylist({
    required String title,
    required String description,
    required PlaylistVisibility visibility,
    List<String> initialTrackIds = const <String>[],
    String? genre,
    String? coverImagePath,
  }) async {
    if (state.isSubmitting) return null;

    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();

    final validationMessage = _validatePlaylistInput(
      title: normalizedTitle,
      description: normalizedDescription,
    );
    if (validationMessage != null) {
      emit(
        state.copyWith(
          errorMessage: validationMessage,
          clearInfo: true,
        ),
      );
      return null;
    }

    if (_titleExists(normalizedTitle)) {
      emit(
        state.copyWith(
          errorMessage: 'A playlist with this name already exists',
          clearInfo: true,
        ),
      );
      return null;
    }

    final normalizedTrackIds = _normalizeTrackIds(initialTrackIds);
    if (normalizedTrackIds.length != initialTrackIds.length) {
      emit(
        state.copyWith(
          errorMessage: 'Playlist tracks contain invalid or duplicate IDs',
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
        title: normalizedTitle,
        description: normalizedDescription,
        visibility: visibility,
        initialTrackIds: normalizedTrackIds,
        genre: genre,
      );
      created = created.copyWith(
        genre: genre,
        clearGenre: genre == null || genre.trim().isEmpty,
        genreId: _playlistGenreId(genre),
        clearGenreId: genre == null || genre.trim().isEmpty,
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
          errorMessage: _playlistErrorMessage(e),
        ),
      );
      return null;
    }
  }

  Future<void> loadPlaylistDetails(
    String playlistId, {
    int? limit,
    int? offset,
  }) async {
    emit(
      state.copyWith(
        isLoadingDetails: true,
        clearError: true,
      ),
    );

    try {
      final playlist = await getPlaylistDetailsUseCase(
        playlistId,
        limit: limit,
        offset: offset,
      );
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
          errorMessage: _playlistErrorMessage(e),
        ),
      );
    }
  }

  Future<void> updatePlaylist({
    required String playlistId,
    String? title,
    String? description,
    PlaylistVisibility? visibility,
    String? genre,
    String? playlistType,
    DateTime? releaseDate,
    List<String>? tags,
    String? coverImagePath,
  }) async {
    if (state.isSubmitting) return;

    final normalizedTitle = title?.trim();
    final normalizedDescription = description?.trim();
    final normalizedGenre = genre?.trim();
    final normalizedGenreId =
        normalizedGenre == null ? null : _playlistGenreId(normalizedGenre);
    final validationMessage = _validatePlaylistInput(
      title: normalizedTitle,
      description: normalizedDescription,
      allowEmptyTitle: title == null,
    );
    if (validationMessage != null) {
      emit(
        state.copyWith(
          errorMessage: validationMessage,
          clearInfo: true,
        ),
      );
      return;
    }

    if (normalizedTitle != null &&
        _titleExists(normalizedTitle, excludingPlaylistId: playlistId)) {
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
        title: normalizedTitle,
        description: normalizedDescription,
        visibility: visibility,
        genre: normalizedGenre,
        playlistType: playlistType,
        releaseDate: releaseDate,
        tags: tags,
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
          title: normalizedTitle,
          description: normalizedDescription,
          visibility: visibility,
          genre: normalizedGenre,
          clearGenre: normalizedGenre != null && normalizedGenre.isEmpty,
          genreId: normalizedGenreId,
          clearGenreId: normalizedGenre != null && normalizedGenre.isEmpty,
          playlistType: playlistType,
          releaseDate: releaseDate,
          tags: tags,
          coverImageUrl: uploadedCoverUrl,
          clearSecretToken: visibility == PlaylistVisibility.publicPlaylist,
        );
      }

      final updatedList = state.playlists.map((playlist) {
        if (playlist.playlistId != playlistId) return playlist;
        return playlist.copyWith(
          title: normalizedTitle,
          description: normalizedDescription,
          visibility: visibility,
          genre: normalizedGenre,
          clearGenre: normalizedGenre != null && normalizedGenre.isEmpty,
          genreId: normalizedGenreId,
          clearGenreId: normalizedGenre != null && normalizedGenre.isEmpty,
          playlistType: playlistType,
          releaseDate: releaseDate,
          tags: tags,
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
          errorMessage: _playlistErrorMessage(e),
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
                  genre: playlist.genre,
                  genreId: playlist.genreId,
                  playlistType: playlist.playlistType,
                  releaseDate: playlist.releaseDate,
                  tags: playlist.tags,
                  coverImageUrl: playlist.coverImageUrl,
                  likesCount: playlist.likesCount,
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
          errorMessage: _playlistErrorMessage(e),
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
      final likedPlaylist =
          state.selectedPlaylist ?? _asLikedPlaylist(previousSelected, true);
      if (likedPlaylist != null && likedPlaylist.playlistId == playlistId) {
        await _likedPlaylistsStore.saveLiked(likedPlaylist);
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Playlist liked',
          clearError: true,
        ),
      );
    } catch (e) {
      if (_isAlreadyLikedError(e)) {
        final likedPlaylist = _asLikedPlaylist(previousSelected, true);
        if (likedPlaylist != null) {
          await _likedPlaylistsStore.saveLiked(likedPlaylist);
        }
        emit(
          state.copyWith(
            isSubmitting: false,
            selectedPlaylist: likedPlaylist ?? _likedSelected(playlistId, true),
            playlists: _setPlaylistLiked(previousPlaylists, playlistId, true),
            infoMessage: 'Playlist liked',
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          selectedPlaylist: previousSelected,
          playlists: previousPlaylists,
          errorMessage: _playlistErrorMessage(e),
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
      await _likedPlaylistsStore.remove(playlistId);
      emit(
        state.copyWith(
          isSubmitting: false,
          infoMessage: 'Playlist unliked',
          clearError: true,
        ),
      );
    } catch (e) {
      if (_isAlreadyUnlikedError(e)) {
        await _likedPlaylistsStore.remove(playlistId);
        emit(
          state.copyWith(
            isSubmitting: false,
            selectedPlaylist: _likedSelected(playlistId, false),
            playlists: _setPlaylistLiked(previousPlaylists, playlistId, false),
            infoMessage: 'Playlist unliked',
            clearError: true,
          ),
        );
        return;
      }
      emit(
        state.copyWith(
          isSubmitting: false,
          selectedPlaylist: previousSelected,
          playlists: previousPlaylists,
          errorMessage: _playlistErrorMessage(e),
        ),
      );
    }
  }

  Future<void> recordPlaylistPlayback(String playlistId) async {
    final recorder = recordPlaylistPlaybackUseCase;
    final normalizedPlaylistId = playlistId.trim();

    if (recorder == null || normalizedPlaylistId.isEmpty) return;

    try {
      await recorder(normalizedPlaylistId);
    } catch (_) {
      // Playback history recording should never block playlist playback.
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
          errorMessage: _playlistErrorMessage(e),
        ),
      );
    }
  }

  Future<bool> addTrackToPlaylist({
    required String playlistId,
    required Track track,
  }) async {
    if (state.isSubmitting) return false;

    final normalizedTrackId = track.id.trim();
    if (normalizedTrackId.isEmpty) {
      emit(
        state.copyWith(
          errorMessage: 'Track ID is required',
          clearInfo: true,
        ),
      );
      return false;
    }

    final selected = state.selectedPlaylist;
    if (selected != null &&
        selected.playlistId == playlistId &&
        selected.tracks.any((item) => item.id.trim() == normalizedTrackId)) {
      emit(
        state.copyWith(
          infoMessage: 'Track is already in this playlist',
          clearError: true,
        ),
      );
      return false;
    }

    emit(state.copyWith(isSubmitting: true, clearError: true, clearInfo: true));
    try {
      await addTrackToPlaylistUseCase(
        playlistId: playlistId,
        trackId: normalizedTrackId,
      );

      PlaylistEntity? updatedSelected = selected;
      if (selected != null && selected.playlistId == playlistId) {
        final alreadyExists =
            selected.tracks.any((item) => item.id.trim() == normalizedTrackId);
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
            playlist.tracks.any((item) => item.id.trim() == normalizedTrackId);
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
      emit(
        state.copyWith(
          isSubmitting: false,
          errorMessage: _playlistErrorMessage(e),
        ),
      );
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
          errorMessage: _playlistErrorMessage(e),
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
    final reorderValidationMessage = _validateReorderTracks(
      currentTracks: previousTracks,
      orderedTracks: orderedTracks,
    );

    if (reorderValidationMessage != null) {
      emit(
        state.copyWith(
          errorMessage: reorderValidationMessage,
          clearInfo: true,
        ),
      );
      return;
    }

    final currentIds = previousTracks.map((track) => track.id.trim()).toList();
    final orderedIds = orderedTracks.map((track) => track.id.trim()).toList();

    if (_sameStringOrder(currentIds, orderedIds)) {
      return;
    }

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
        orderedTrackIds: orderedIds,
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
          errorMessage: _playlistErrorMessage(e),
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
          errorMessage: _playlistErrorMessage(e),
        ),
      );
    }
  }

  Future<void> loadEmbedCode(
    String playlistId, {
    String? theme,
    bool? autoplay,
    int? start,
    bool? hideArtwork,
    int? width,
    int? height,
  }) async {
    emit(
      state.copyWith(
        isSubmitting: true,
        clearError: true,
        clearInfo: true,
      ),
    );

    try {
      final embedCode = await getPlaylistEmbedCodeUseCase(
        playlistId,
        theme: theme,
        autoplay: autoplay,
        start: start,
        hideArtwork: hideArtwork,
        width: width,
        height: height,
      );
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
          errorMessage: _playlistErrorMessage(e),
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

  List<PlaylistEntity> _appendUniquePlaylists(
    List<PlaylistEntity> source,
    List<PlaylistEntity> next,
  ) {
    if (source.isEmpty) return next;

    final result = source.toList(growable: true);
    final seenIds = source.map((playlist) => playlist.playlistId).toSet();

    for (final playlist in next) {
      if (playlist.playlistId.isEmpty) continue;
      if (!seenIds.add(playlist.playlistId)) continue;
      result.add(playlist);
    }

    return result.toList(growable: false);
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
    return selected.copyWith(
      isLiked: isLiked,
      likesCount: _nextLikesCount(selected, isLiked),
    );
  }

  List<PlaylistEntity> _setPlaylistLiked(
    List<PlaylistEntity> playlists,
    String playlistId,
    bool isLiked,
  ) {
    return playlists.map((playlist) {
      if (playlist.playlistId != playlistId) return playlist;
      return playlist.copyWith(
        isLiked: isLiked,
        likesCount: _nextLikesCount(playlist, isLiked),
      );
    }).toList(growable: false);
  }

  int _nextLikesCount(PlaylistEntity playlist, bool isLiked) {
    if (playlist.isLiked == isLiked) return playlist.likesCount;
    final delta = isLiked ? 1 : -1;
    final next = playlist.likesCount + delta;
    return next < 0 ? 0 : next;
  }

  PlaylistEntity? _asLikedPlaylist(
    PlaylistEntity? playlist,
    bool isLiked,
  ) {
    if (playlist == null) return null;
    return playlist.copyWith(
      isLiked: isLiked,
      likesCount: _nextLikesCount(playlist, isLiked),
    );
  }

  bool _isAlreadyLikedError(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('already') && normalized.contains('liked');
  }

  bool _isAlreadyUnlikedError(Object error) {
    final normalized = error.toString().toLowerCase();
    return normalized.contains('not liked') ||
        (normalized.contains('already') && normalized.contains('unliked'));
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

  String? _validatePlaylistInput({
    required String? title,
    required String? description,
    bool allowEmptyTitle = false,
  }) {
    final normalizedTitle = title?.trim() ?? '';
    final normalizedDescription = description?.trim() ?? '';

    if (!allowEmptyTitle && normalizedTitle.isEmpty) {
      return 'Playlist title is required';
    }

    if (normalizedTitle.length > _kPlaylistTitleMaxLength) {
      return 'Playlist title must be $_kPlaylistTitleMaxLength characters or less';
    }

    if (normalizedDescription.length > _kPlaylistDescriptionMaxLength) {
      return 'Playlist description must be $_kPlaylistDescriptionMaxLength characters or less';
    }

    return null;
  }

  List<String> _normalizeTrackIds(List<String> trackIds) {
    final normalized = <String>[];
    final seen = <String>{};

    for (final trackId in trackIds) {
      final value = trackId.trim();
      if (value.isEmpty || seen.contains(value)) continue;
      seen.add(value);
      normalized.add(value);
    }

    return normalized;
  }

  String? _validateReorderTracks({
    required List<Track> currentTracks,
    required List<Track> orderedTracks,
  }) {
    final currentIds = currentTracks.map((track) => track.id.trim()).toList();
    final orderedIds = orderedTracks.map((track) => track.id.trim()).toList();

    if (orderedIds.any((id) => id.isEmpty)) {
      return 'Playlist tracks contain invalid IDs';
    }

    if (orderedIds.toSet().length != orderedIds.length) {
      return 'Playlist tracks contain duplicate IDs';
    }

    if (currentIds.length != orderedIds.length) {
      return 'Reordered tracks must match the current playlist tracks';
    }

    final currentSet = currentIds.toSet();
    final orderedSet = orderedIds.toSet();

    if (currentSet.length != currentIds.length ||
        currentSet.length != orderedSet.length) {
      return 'Reordered tracks must match the current playlist tracks';
    }

    if (!currentSet.containsAll(orderedSet)) {
      return 'Reordered tracks must match the current playlist tracks';
    }

    return null;
  }

  bool _sameStringOrder(List<String> first, List<String> second) {
    if (first.length != second.length) return false;

    for (var index = 0; index < first.length; index++) {
      if (first[index] != second[index]) return false;
    }

    return true;
  }

  String _playlistErrorMessage(Object error) {
    final normalized = error.toString().toLowerCase();

    if (normalized.contains('401') ||
        normalized.contains('unauthorized') ||
        normalized.contains('not authenticated')) {
      return 'Please log in again';
    }

    if (normalized.contains('403') ||
        normalized.contains('forbidden') ||
        normalized.contains('permission')) {
      return 'You do not have permission to do this';
    }

    if (normalized.contains('404') || normalized.contains('not found')) {
      return 'Playlist not found';
    }

    if (normalized.contains('409')) {
      if (normalized.contains('already') && normalized.contains('liked')) {
        return 'Playlist already liked';
      }
      if (normalized.contains('not liked')) {
        return 'Playlist is not liked';
      }
      return 'This playlist action was already done';
    }

    if (normalized.contains('400') ||
        normalized.contains('bad request') ||
        normalized.contains('validation')) {
      return 'Invalid playlist data';
    }

    if (normalized.contains('timeout') ||
        normalized.contains('connection') ||
        normalized.contains('network')) {
      return 'Network error. Please check your connection';
    }

    return 'Something went wrong. Please try again';
  }

  int? _playlistGenreId(String? genre) => playlistGenreId(genre);
}
