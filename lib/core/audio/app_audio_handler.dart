import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:audio_session/audio_session.dart';

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();

  AppAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    final session = await AudioSession.instance;
    await session.configure(const AudioSessionConfiguration.music());

    // ================= PLAYBACK STATE =================
    _player.playerStateStream.listen((state) {
      _broadcastState(state);
    });

    // ================= POSITION =================
    _player.positionStream.listen((position) {
      final current = playbackState.value;

      playbackState.add(
        current.copyWith(
          updatePosition: position,
        ),
      );
    });

    // ================= INDEX CHANGE =================
    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(queue.value[index]);
      }
    });

    // ================= DURATION FIX (CRITICAL) =================
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;

      if (current != null) {
        mediaItem.add(
          current.copyWith(
            duration: duration ?? const Duration(seconds: 1),
          ),
        );
      }
    });

    // ================= EXTRA SAFETY =================
    _player.sequenceStateStream.listen((sequenceState) {
      final index = sequenceState.currentIndex;
      final duration = _player.duration;

      if (index != null && index < queue.value.length) {
        final item = queue.value[index];

        mediaItem.add(
          item.copyWith(
            duration: duration ?? const Duration(seconds: 1),
          ),
        );
      }
    });
  }

  void _broadcastState(PlayerState state) {
    playbackState.add(
      PlaybackState(
        controls: [
          if (!state.playing) MediaControl.play,
          if (state.playing) MediaControl.pause,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0],
        processingState: _mapState(state.processingState),
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
      ),
    );
  }

  // ================= QUEUE =================

  Future<void> setQueue(List<MediaItem> items) async {
    queue.add(items);

    final sources = items.map((item) {
      final url = item.extras?['url'] as String;
      return AudioSource.uri(Uri.parse(url));
    }).toList();

    await _player.setAudioSources(sources);

    // 🔥 CRITICAL: duration must NOT be null
    if (items.isNotEmpty) {
      mediaItem.add(
        items.first.copyWith(
          duration: const Duration(seconds: 1),
        ),
      );
    }
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);

    if (index < queue.value.length) {
      mediaItem.add(queue.value[index]);
    }
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();

    final index = _player.currentIndex;
    if (index != null && index < queue.value.length) {
      mediaItem.add(queue.value[index]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();

    final index = _player.currentIndex;
    if (index != null && index < queue.value.length) {
      mediaItem.add(queue.value[index]);
    }
  }

  // ================= CONTROLS =================

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  /// Sets the player output volume in the 0.0..1.0 range.
  /// This takes effect immediately, including during active playback.
  Future<void> setVolume(double volume) => _player.setVolume(volume);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  // ================= HELPER =================

  AudioProcessingState _mapState(ProcessingState state) {
    switch (state) {
      case ProcessingState.idle:
        return AudioProcessingState.idle;
      case ProcessingState.loading:
        return AudioProcessingState.loading;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
    }
  }
}
