import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/offline_repository.dart';
import 'offline_state.dart';

class OfflineCubit extends Cubit<OfflineState> {
  final OfflineRepository repo;

  OfflineCubit(this.repo) : super(const OfflineState()) {
    _load();
  }

  Future<void> download(String trackId) async {
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

  bool isDownloaded(String trackId) {
    return state.downloadedTracks.containsKey(trackId);
  }

  String? getPath(String trackId) {
    return state.downloadedTracks[trackId];
  }

  Future<void> _load() async {
    try {
      final saved = await repo.getDownloadedTracks();
      emit(state.copyWith(downloadedTracks: saved));
    } catch (_) {
      // fallback to empty if anything fails
      emit(const OfflineState());
    }
  }
}
