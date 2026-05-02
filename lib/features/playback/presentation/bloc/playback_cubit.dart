// features/playback/presentation/bloc/playback_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/data/repositories/queue_repository.dart';

import 'playback_state.dart';

class PlaybackCubit extends Cubit<PlaybackState> {
  final AudioPlayerService audioPlayerService;
  final QueueRepository queueRepository;

  PlaybackCubit(this.audioPlayerService, this.queueRepository)
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

    // ✅ أبلغ الـ backend بالـ queue الجديدة
    await queueRepository.loadQueue(
      trackIds: queue.map((t) => t.id).toList(),
      startIndex: _currentIndex,
    );

    await audioPlayerService.playFromContext(
      tracks: queue,
      startIndex: _currentIndex,
      source: 'playback_cubit',
    );
  }

  Future<void> pause() async {
    if (!state.isPlaying) return;
    await audioPlayerService.pause();
    emit(state.copyWith(isPlaying: false));
  }

  Future<void> resume() async {
    if (state.currentTrack == null) return;
    await audioPlayerService.resume();
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

  // ── Next / Previous — backend-aware ──────────────────────────────────────

  Future<void> playNext() async {
    if (state.queue.isEmpty || _currentIndex < 0) return;
    if (_currentIndex >= state.queue.length - 1) return;

    // أبلغ الـ backend أولاً
    final nextTrack = await queueRepository.next();

    _currentIndex++;
    final localNext = nextTrack ?? state.queue[_currentIndex];

    emit(state.copyWith(currentTrack: localNext, isPlaying: true));
    await audioPlayerService.play(localNext);
  }

  Future<void> playPrevious() async {
    if (state.queue.isEmpty || _currentIndex <= 0) return;

    final prevTrack = await queueRepository.previous();

    _currentIndex--;
    final localPrev = prevTrack ?? state.queue[_currentIndex];

    emit(state.copyWith(currentTrack: localPrev, isPlaying: true));
    await audioPlayerService.play(localPrev);
  }

  /// القفز لأغنية محددة بالـ index في الـ queue
  Future<void> jumpToIndex(int index) async {
    if (index < 0 || index >= state.queue.length) return;

    final jumped = await queueRepository.jumpTo(index);
    _currentIndex = index;

    final track = jumped ?? state.queue[index];
    emit(state.copyWith(currentTrack: track, isPlaying: true));
    await audioPlayerService.play(track);
  }

  Future<void> seek(Duration position) async {
    await audioPlayerService.seek(position);
  }

  List<Track> getQueue() => state.queue;

  // ── Queue manipulation (local + reload backend) ──────────────────────────

  void addPlayNext(Track track) {
    final queue = List<Track>.from(state.queue);
    queue.removeWhere((t) => t.id == track.id);

    if (queue.isEmpty || _currentIndex < 0) {
      queue.insert(0, track);
      _currentIndex = 0;
    } else {
      final insertAt = (_currentIndex + 1).clamp(0, queue.length);
      queue.insert(insertAt, track);
    }

    emit(state.copyWith(queue: queue));

    // sync مع الـ backend
    _syncQueueToBackend(queue);
  }

  void addPlayLast(Track track) {
    final queue = List<Track>.from(state.queue);
    queue.removeWhere((t) => t.id == track.id);

    if (state.currentTrack != null) {
      final newIndex = queue.indexWhere((t) => t.id == state.currentTrack!.id);
      if (newIndex >= 0) _currentIndex = newIndex;
    }

    queue.add(track);
    emit(state.copyWith(queue: queue));

    _syncQueueToBackend(queue);
  }

  void _syncQueueToBackend(List<Track> queue) {
    // fire-and-forget — مش محتاجين ننتظر الـ response
    queueRepository.loadQueue(
      trackIds: queue.map((t) => t.id).toList(),
      startIndex: _currentIndex.clamp(0, queue.length - 1),
    );
  }
}