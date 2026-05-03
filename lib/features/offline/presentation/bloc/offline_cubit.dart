import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';

import '../../data/repositories/offline_repository.dart';
import 'offline_state.dart';

class OfflineCubit extends Cubit<OfflineState> {
  final OfflineRepository repo;

  OfflineCubit(this.repo) : super(const OfflineState()) {
    _load();
  }

  Future<void> download(String trackId) async {
    final normalizedTrackId = trackId.trim();

    if (normalizedTrackId.isEmpty) {
      throw Exception('DOWNLOAD_FAILED');
    }

    if (isDownloaded(normalizedTrackId)) return;

    try {
      final path = await repo.downloadTrack(normalizedTrackId);

      final updatedTracks = Map<String, String>.from(state.downloadedTracks);
      updatedTracks[normalizedTrackId] = path;

      final updatedDetails = Map<String, Track>.from(
        await repo.getDownloadedTrackDetails(),
      );

      final downloadedDetail = updatedDetails[normalizedTrackId];
      if (downloadedDetail != null) {
        updatedDetails[normalizedTrackId] = downloadedDetail.copyWith(
          localPath: path,
        );
      }

      await repo.saveDownloadedTracks(updatedTracks);
      await repo.saveDownloadedTrackDetails(updatedDetails);

      emit(
        state.copyWith(
          downloadedTracks: updatedTracks,
          downloadedTrackDetails: updatedDetails,
        ),
      );
    } catch (error) {
      throw Exception(_mapDownloadError(error));
    }
  }

  Future<void> downloadTrack(Track track) async {
    final normalizedTrackId = track.id.trim();

    if (normalizedTrackId.isEmpty) {
      throw Exception('DOWNLOAD_FAILED');
    }

    if (!isDownloaded(normalizedTrackId)) {
      await download(normalizedTrackId);
    }

    final path = getPath(normalizedTrackId);
    final updatedDetails = Map<String, Track>.from(
      state.downloadedTrackDetails,
    );

    final savedDetails = updatedDetails[normalizedTrackId];

    updatedDetails[normalizedTrackId] = (savedDetails ?? track).copyWith(
      id: normalizedTrackId,
      title: track.title,
      artist: track.artist,
      audioUrl: track.audioUrl,
      artworkUrl: track.artworkUrl,
      handle: track.handle,
      artistId: track.artistId,
      likesCount: track.likesCount,
      repostsCount: track.repostsCount,
      durationMs: track.durationMs,
      localPath: path ?? savedDetails?.localPath ?? track.localPath,
    );

    await repo.saveDownloadedTrackDetails(updatedDetails);

    emit(
      state.copyWith(
        downloadedTrackDetails: updatedDetails,
      ),
    );
  }

  Future<void> saveDownloadedPlaylist(PlaylistEntity playlist) async {
    final repairedTracks = playlist.tracks.map((track) {
      final saved = state.downloadedTrackDetails[track.id];
      final path = getPath(track.id);

      return (saved ?? track).copyWith(
        localPath: path ?? saved?.localPath ?? track.localPath,
      );
    }).toList(growable: false);

    final updatedPlaylists = Map<String, PlaylistEntity>.from(
      state.downloadedPlaylists,
    );

    updatedPlaylists[playlist.playlistId] = playlist.copyWith(
      tracks: repairedTracks,
      tracksCount: repairedTracks.length,
    );

    await repo.saveDownloadedPlaylists(updatedPlaylists);

    emit(
      state.copyWith(
        downloadedPlaylists: updatedPlaylists,
      ),
    );
  }

  Future<void> removeDownloadedTrack(String trackId) async {
    final normalizedTrackId = trackId.trim();
    if (normalizedTrackId.isEmpty) return;

    final updatedTracks = Map<String, String>.from(state.downloadedTracks);
    final updatedDetails = Map<String, Track>.from(
      state.downloadedTrackDetails,
    );

    updatedTracks.remove(normalizedTrackId);
    updatedDetails.remove(normalizedTrackId);

    await repo.saveDownloadedTracks(updatedTracks);
    await repo.saveDownloadedTrackDetails(updatedDetails);

    emit(
      state.copyWith(
        downloadedTracks: updatedTracks,
        downloadedTrackDetails: updatedDetails,
      ),
    );
  }

  Future<void> removeDownloadedPlaylist(String playlistId) async {
    final normalizedPlaylistId = playlistId.trim();
    if (normalizedPlaylistId.isEmpty) return;

    final updatedPlaylists = Map<String, PlaylistEntity>.from(
      state.downloadedPlaylists,
    );

    updatedPlaylists.remove(normalizedPlaylistId);

    await repo.saveDownloadedPlaylists(updatedPlaylists);

    emit(
      state.copyWith(
        downloadedPlaylists: updatedPlaylists,
      ),
    );
  }

  Future<void> reload() {
    return _load();
  }

  bool isDownloaded(String trackId) {
    return state.downloadedTracks.containsKey(trackId.trim());
  }

  bool isPlaylistDownloaded(String playlistId) {
    return state.downloadedPlaylists.containsKey(playlistId.trim());
  }

  String? getPath(String trackId) {
    return state.downloadedTracks[trackId.trim()];
  }

  Track? getDownloadedTrack(String trackId) {
    return state.downloadedTrackDetails[trackId.trim()];
  }

  PlaylistEntity? getDownloadedPlaylist(String playlistId) {
    return state.downloadedPlaylists[playlistId.trim()];
  }

  Future<void> _load() async {
    try {
      final savedTracks = await repo.getDownloadedTracks();
      final trackDetails = Map<String, Track>.from(
        await repo.getDownloadedTrackDetails(),
      );

      var repairedDetails = false;

      for (final entry in savedTracks.entries) {
        final savedDetail = trackDetails[entry.key];

        if (savedDetail != null) {
          if (savedDetail.localPath != entry.value) {
            trackDetails[entry.key] = savedDetail.copyWith(
              localPath: entry.value,
            );
            repairedDetails = true;
          }

          continue;
        }

        final detail = await repo.fetchTrackDetails(entry.key);
        if (detail == null) continue;

        trackDetails[entry.key] = detail.copyWith(localPath: entry.value);
        repairedDetails = true;
      }

      if (repairedDetails) {
        await repo.saveDownloadedTrackDetails(trackDetails);
      }

      final playlists = await repo.getDownloadedPlaylists();

      if (isClosed) return;

      emit(
        state.copyWith(
          downloadedTracks: savedTracks,
          downloadedTrackDetails: trackDetails,
          downloadedPlaylists: playlists,
        ),
      );
    } catch (_) {
      if (isClosed) return;

      emit(const OfflineState());
    }
  }

  String _mapDownloadError(Object error) {
    final text = error.toString().toLowerCase();

    if (text.contains('upgrade_required') ||
        text.contains('premium') ||
        text.contains('subscription') ||
        text.contains('403') ||
        text.contains('401')) {
      return 'UPGRADE_REQUIRED';
    }

    if (text.contains('empty')) {
      return 'DOWNLOAD_EMPTY';
    }

    return 'DOWNLOAD_FAILED';
  }
}
