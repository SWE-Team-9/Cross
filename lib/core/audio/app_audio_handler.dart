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

    // 🔥 Playback state
    _player.playerStateStream.listen((state) {
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
        ),
      );
    });

    // 🔥 Smooth seek bar
    _player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(
          updatePosition: position,
        ),
      );
    });

    // 🔥 FIX 1: SYNC CURRENT TRACK WITH INDEX
    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        final currentItem = queue.value[index];
        mediaItem.add(currentItem);
      }
    });

    // 🔥 FIX 2: SET REAL DURATION AFTER LOAD (CRITICAL FIX)
    _player.durationStream.listen((duration) {
      final current = mediaItem.value;

      if (duration != null && current != null) {
        mediaItem.add(
          current.copyWith(duration: duration),
        );
      }
    });
  }

  // ========================= QUEUE LOGIC =========================

  Future<void> setQueue(List<MediaItem> items) async {
    queue.add(items);

    final sources = items.map((item) {
      final url = item.extras?['url'] as String;
      return AudioSource.uri(Uri.parse(url));
    }).toList();

    await _player.setAudioSources(sources);

    // 🔥 Set first item (WITHOUT duration)
    if (items.isNotEmpty) {
      mediaItem.add(items.first);
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

    final nextIndex = _player.currentIndex;
    if (nextIndex != null && nextIndex < queue.value.length) {
      mediaItem.add(queue.value[nextIndex]);
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();

    final prevIndex = _player.currentIndex;
    if (prevIndex != null && prevIndex < queue.value.length) {
      mediaItem.add(queue.value[prevIndex]);
    }
  }

  // ========================= PLAYER CONTROLS =========================

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) => _player.seek(position);

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> onTaskRemoved() async {
    await stop();
  }

  // ========================= HELPERS =========================

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
