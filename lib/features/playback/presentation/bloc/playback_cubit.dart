// features/playback/presentation/bloc/playback_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';

import 'playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  final AudioPlayerService audioPlayerService;

  PlaybackCubit(this.audioPlayerService)
      : super(const PlaybackState(isAvailable: true));

  int _currentIndex = -1;

  // ── Core playback ────────────────────────────────────────────────────────

  Future<void> playTrack(Track track, List<Track> queue) async {
    if (queue.isEmpty) return;

    final index = queue.indexWhere((t) => t.id == track.id);
    _currentIndex = index >= 0 ? index : 0;

    emit(state.copyWith(
      currentTrack: queue[_currentIndex],
      queue: queue,
      isPlaying: true,
    ));

    await audioPlayerService.play(queue[_currentIndex]);
  }

  Future<void> pause() async {
    if (!state.isPlaying) return;
    await audioPlayerService.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> resume() async {
    final track = state.currentTrack;
    if (track == null) return;
    await audioPlayerService.play(track);
    emit(state.copyWith(isPlaying: true));
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
    emit(state.copyWith(
      isPlaying: false,
      currentTrack: null,
      queue: const [],
    ));
  }

  Future<void> playNext() async {
    if (state.queue.isEmpty || _currentIndex < 0) return;
    if (_currentIndex >= state.queue.length - 1) return;

    _currentIndex++;
    final nextTrack = state.queue[_currentIndex];
    emit(state.copyWith(currentTrack: nextTrack, isPlaying: true));
    await audioPlayerService.play(nextTrack);
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty || _currentIndex <= 0) return;

    _currentIndex--;
    final prevTrack = state.queue[_currentIndex];
    emit(state.copyWith(currentTrack: prevTrack, isPlaying: true));
    await audioPlayerService.play(prevTrack);
  }

  Future<void> seek(Duration position) async {
    await audioPlayerService.seek(position);
  }

  List<Track> getQueue() => state.queue;

  // ── Queue manipulation (3-dot menu actions) ──────────────────────────────

  /// Inserts [track] immediately after the currently playing track.
  /// If nothing is playing, adds it to the front.
  /// Matches SoundCloud "Play Next" behaviour.
  void addPlayNext(Track track) {
    final queue = List<Track>.from(state.queue);

    // Remove if already in queue (avoid duplicates)
    queue.removeWhere((t) => t.id == track.id);

    if (queue.isEmpty || _currentIndex < 0) {
      // Nothing playing — put it first
      queue.insert(0, track);
      _currentIndex = 0;
    } else {
      // Insert right after current
      final insertAt = (_currentIndex + 1).clamp(0, queue.length);
      queue.insert(insertAt, track);
      // _currentIndex stays the same — current track didn't move
    }

    emit(state.copyWith(queue: queue));
  }

  /// Appends [track] to the very end of the queue.
  /// Matches SoundCloud "Play Last" behaviour.
  void addPlayLast(Track track) {
    final queue = List<Track>.from(state.queue);

    // Remove if already in queue (avoid duplicates)
    queue.removeWhere((t) => t.id == track.id);

    // If removing shifted our current index, fix it
    // (only matters if the removed track was before current)
    // We re-find current track by id to be safe
    if (state.currentTrack != null) {
      final newIndex =
          queue.indexWhere((t) => t.id == state.currentTrack!.id);
      if (newIndex >= 0) _currentIndex = newIndex;
    }

    queue.add(track);

    emit(state.copyWith(queue: queue));
  }
}