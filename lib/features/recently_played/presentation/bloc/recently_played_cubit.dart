import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class RecentlyPlayedCubit extends Cubit<List<Track>> {
  RecentlyPlayedCubit() : super(<Track>[]);

  void addTrack(Track track) {
    final updated = List<Track>.from(state);

    updated.removeWhere((t) => t.id == track.id);

    updated.insert(0, track);

    if (updated.length > 20) {
      updated.removeLast();
    }

    emit(updated);
  }

  void clear() {
    emit(<Track>[]);
  }
}
