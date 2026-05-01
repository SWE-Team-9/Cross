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
    if (isDownloaded(trackId)) return;

    try {
      final path = await repo.downloadTrack(trackId);

      final updated = Map<String, String>.from(state.downloadedTracks);
      updated[trackId] = path;

      // ✅ persist
      await repo.saveDownloadedTracks(updated);

      emit(state.copyWith(downloadedTracks: updated));
    } catch (e) {
      if (e.toString().contains('403')) {
        throw Exception('UPGRADE_REQUIRED');
      }
      throw Exception('DOWNLOAD_FAILED');
    }
  }

  Future<void> downloadTrack(Track track) async {
    if (!isDownloaded(track.id)) {
      await download(track.id);
    }

    final path = getPath(track.id);
    final updatedDetails = Map<String, Track>.from(
      state.downloadedTrackDetails,
    );
    updatedDetails[track.id] = track.copyWith(
      localPath: path ?? track.localPath,
    );

    await repo.saveDownloadedTrackDetails(updatedDetails);
    emit(state.copyWith(downloadedTrackDetails: updatedDetails));
  }

  Future<void> saveDownloadedPlaylist(PlaylistEntity playlist) async {
    final tracks = playlist.tracks.map((track) {
      final saved = state.downloadedTrackDetails[track.id];
      final path = getPath(track.id);
      return (saved ?? track).copyWith(localPath: path ?? saved?.localPath);
    }).toList(growable: false);

    final updatedPlaylists = Map<String, PlaylistEntity>.from(
      state.downloadedPlaylists,
    );
    updatedPlaylists[playlist.playlistId] = playlist.copyWith(
      tracks: tracks,
      tracksCount: tracks.length,
    );

    await repo.saveDownloadedPlaylists(updatedPlaylists);
    emit(state.copyWith(downloadedPlaylists: updatedPlaylists));
  }

  bool isDownloaded(String trackId) {
    return state.downloadedTracks.containsKey(trackId);
  }

  String? getPath(String trackId) {
    return state.downloadedTracks[trackId];
  }

  Future<void> _load() async {
    try {
      final saved = await repo.getDownloadedTracks();
      final trackDetails = Map<String, Track>.from(
        await repo.getDownloadedTrackDetails(),
      );
      var repairedDetails = false;
      for (final entry in saved.entries) {
        if (trackDetails.containsKey(entry.key)) continue;
        final detail = await repo.fetchTrackDetails(entry.key);
        if (detail == null) continue;
        trackDetails[entry.key] = detail.copyWith(localPath: entry.value);
        repairedDetails = true;
      }
      if (repairedDetails) {
        await repo.saveDownloadedTrackDetails(trackDetails);
      }
      final playlists = await repo.getDownloadedPlaylists();
      emit(
        state.copyWith(
          downloadedTracks: saved,
          downloadedTrackDetails: trackDetails,
          downloadedPlaylists: playlists,
        ),
      );
    } catch (_) {
      // fallback to empty if anything fails
      emit(const OfflineState());
    }
  }
}
