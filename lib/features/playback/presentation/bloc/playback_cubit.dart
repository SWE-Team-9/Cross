import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';

import 'playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  final AudioPlayerService audioPlayerService;

  PlaybackCubit(this.audioPlayerService)
      : super(const PlaybackState(isAvailable: true));

  int _currentIndex = -1;

  Future<void> playTrack(Track track, List<Track> queue) async {
    if (queue.isEmpty) return;

    final index = queue.indexWhere((t) => t.id == track.id);

    _currentIndex = index >= 0 ? index : 0;

    emit(
      state.copyWith(
        currentTrack: queue[_currentIndex],
        queue: queue,
        isPlaying: true,
      ),
    );

    await audioPlayerService.play(queue[_currentIndex]);
  }

  Future<void> pause() async {
    if (!state.isPlaying) return;

    await audioPlayerService.pause();

    emit(
      state.copyWith(
        isPlaying: false,
      ),
    );
  }

  Future<void> resume() async {
    final track = state.currentTrack;
    if (track == null) return;

    await audioPlayerService.play(track);

    emit(
      state.copyWith(
        isPlaying: true,
      ),
    );
  }

  Future<void> togglePlayPause() async {
    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  Future<void> stop() async {
    await audioPlayerService.stop();

    _currentIndex = -1;

    emit(
      state.copyWith(
        isPlaying: false,
        currentTrack: null,
        queue: const [],
      ),
    );
  }

  Future<void> playNext() async {
    if (state.queue.isEmpty) return;
    if (_currentIndex < 0) return;
    if (_currentIndex >= state.queue.length - 1) return;

    _currentIndex++;

    final nextTrack = state.queue[_currentIndex];

    emit(
      state.copyWith(
        currentTrack: nextTrack,
        isPlaying: true,
      ),
    );

    await audioPlayerService.play(nextTrack);
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty) return;
    if (_currentIndex <= 0) return;

    _currentIndex--;

    final prevTrack = state.queue[_currentIndex];

    emit(
      state.copyWith(
        currentTrack: prevTrack,
        isPlaying: true,
      ),
    );

    await audioPlayerService.play(prevTrack);
  }

  Future<void> seek(Duration position) async {
    await audioPlayerService.seek(position);
  }

  List<Track> getQueue() {
    return state.queue;
  }
}
