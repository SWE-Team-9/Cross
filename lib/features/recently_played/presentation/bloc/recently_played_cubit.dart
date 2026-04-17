import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';

import '../../domain/usecases/get_recently_played.dart';

class RecentlyPlayedCubit extends Cubit<List<Track>> {
  RecentlyPlayedCubit({
    this.getRecentlyPlayed,
    this.recordRecentlyPlayed,
  }) : super(<Track>[]);

  final GetRecentlyPlayed? getRecentlyPlayed;
  final RecordRecentlyPlayed? recordRecentlyPlayed;

  Future<void> loadListeningHistory() async {
    final loader = getRecentlyPlayed;
    if (loader == null) return;

    try {
      final tracks = await loader();
      if (tracks.isNotEmpty) {
        emit(tracks);
      }
    } catch (_) {
      // keep in-memory state as fallback
    }
  }

  void addTrack(Track track) {
    final updated = List<Track>.from(state);

    updated.removeWhere((t) => t.id == track.id);

    updated.insert(0, track);

    if (updated.length > 20) {
      updated.removeLast();
    }

    emit(updated);

    final recorder = recordRecentlyPlayed;
    if (recorder != null) {
      recorder(track.id);
    }
  }

  Future<void> recordTrackPlay(String trackId) async {
    final recorder = recordRecentlyPlayed;
    if (recorder == null) return;
    try {
      await recorder(trackId);
    } catch (_) {
      // ignore remote errors for optimistic UX
    }
  }

  void clear() {
    emit(<Track>[]);
  }
}
