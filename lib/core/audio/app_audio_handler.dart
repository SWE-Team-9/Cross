// coverage:ignore-file
// ignore_for_file: experimental_member_use

import 'package:audio_service/audio_service.dart';
import 'package:audio_session/audio_session.dart';
import 'package:get_it/get_it.dart';
import 'package:just_audio/just_audio.dart';

import '../../features/playback/data/datasources/track_detail_remote_data_source.dart';
import '../models/player_state.dart' as app_player;

class AppAudioHandler extends BaseAudioHandler with QueueHandler, SeekHandler {
  final AudioPlayer _player = AudioPlayer();
  app_player.AppRepeatMode _repeatMode = app_player.AppRepeatMode.off;

  final Map<String, String> _resolvedUrls = {};
  
  // Track if audio session has been initialized
  static bool _audioSessionInitialized = false;

  AppAudioHandler() {
    _init();
  }

  Future<void> _init() async {
    // Initialize audio session only once globally
    if (!_audioSessionInitialized) {
      _audioSessionInitialized = true;
      try {
        final session = await AudioSession.instance;
        // Configure with music profile - this handles permissions once at startup
        await session.configure(const AudioSessionConfiguration.music());
      } catch (_) {
        // If audio session fails, continue without it
      }
    }

    _player.playerStateStream.listen((state) {
      _broadcastState(state);
    });

    _player.positionStream.listen((position) {
      playbackState.add(
        playbackState.value.copyWith(updatePosition: position),
      );
    });

    _player.currentIndexStream.listen((index) {
      if (index != null && index < queue.value.length) {
        mediaItem.add(_mediaItemForIndex(index));
      }
    });

    _player.durationStream.listen((duration) {
      final current = mediaItem.value;
      if (current != null) {
        mediaItem.add(
          current.copyWith(
            duration: duration ?? current.duration,
          ),
        );
      }
    });

    _player.sequenceStateStream.listen((sequenceState) {
      final index = sequenceState.currentIndex;
      final duration = _player.duration;
      if (index != null && index < queue.value.length) {
        mediaItem.add(_mediaItemForIndex(index, duration: duration));
      }
    });
  }

  void _broadcastState(PlayerState state) {
    playbackState.add(
      PlaybackState(
        controls: [
          MediaControl.rewind,
          if (!state.playing) MediaControl.play,
          if (state.playing) MediaControl.pause,
          MediaControl.fastForward,
        ],
        systemActions: const {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
        },
        androidCompactActionIndices: const [0, 1, 2],
        processingState: _mapState(state.processingState),
        playing: state.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
        queueIndex: _player.currentIndex,
        repeatMode: _audioServiceRepeatMode(_repeatMode),
      ),
    );
  }

  // ── Queue ─────────────────────────────────────────────────────────────────

  Future<void> setQueue(List<MediaItem> items) async {
    final preparedItems = items.map(_withNotificationDuration).toList();
    queue.add(preparedItems);

    final sources = await Future.wait(
      preparedItems.map(_buildAudioSource),
    );

    await _player.setAudioSources(sources);

    if (preparedItems.isNotEmpty) {
      mediaItem.add(preparedItems.first);
    }
  }

  Future<AudioSource> _buildAudioSource(MediaItem item) async {
    final localPath = item.extras?['localPath'] as String?;
    if (localPath != null && localPath.isNotEmpty) {
      return AudioSource.file(localPath, tag: item);
    }

    final rawUrl = (item.extras?['url'] as String?) ?? '';

    if (rawUrl.trim().isNotEmpty) {
      _resolvedUrls[item.id] = rawUrl;
      return AudioSource.uri(Uri.parse(rawUrl), tag: item);
    }

    final cached = _resolvedUrls[item.id];
    if (cached != null && cached.isNotEmpty) {
      return AudioSource.uri(Uri.parse(cached), tag: item);
    }

    try {
      final dataSource = GetIt.I<TrackDetailRemoteDataSource>();
      final sourceDto = await dataSource.fetchStreamSource(item.id);
      final url = sourceDto.streamUrl;

      if (url.isNotEmpty) {
        _resolvedUrls[item.id] = url;
        return AudioSource.uri(Uri.parse(url), tag: item);
      }
    } catch (_) {
      // Keep playback safe by falling back to silence.
    }

    return _SilentAudioSource(item);
  }

  @override
  Future<void> skipToQueueItem(int index) async {
    await _player.seek(Duration.zero, index: index);
    if (index < queue.value.length) {
      mediaItem.add(_mediaItemForIndex(index));
    }
  }

  @override
  Future<void> skipToNext() async {
    await _player.seekToNext();
    final index = _player.currentIndex;
    if (index != null && index < queue.value.length) {
      mediaItem.add(_mediaItemForIndex(index));
    }
  }

  @override
  Future<void> skipToPrevious() async {
    await _player.seekToPrevious();
    final index = _player.currentIndex;
    if (index != null && index < queue.value.length) {
      mediaItem.add(_mediaItemForIndex(index));
    }
  }

  // ── Controls ──────────────────────────────────────────────────────────────

  @override
  Future<void> play() => _player.play();

  @override
  Future<void> pause() => _player.pause();

  @override
  Future<void> seek(Duration position) async {
    final safePosition = _clampPosition(position);
    await _player.seek(safePosition);
    playbackState.add(
      playbackState.value.copyWith(
        updatePosition: safePosition,
        bufferedPosition: _player.bufferedPosition,
      ),
    );
  }

  @override
  Future<void> fastForward() {
    return _seekRelative(AudioService.config.fastForwardInterval);
  }

  @override
  Future<void> rewind() {
    return _seekRelative(-AudioService.config.rewindInterval);
  }

  Future<void> _seekRelative(Duration offset) {
    return seek(_player.position + offset);
  }

  Duration _clampPosition(Duration position) {
    if (position < Duration.zero) return Duration.zero;

    final duration = _player.duration;
    if (duration != null && position > duration) return duration;

    return position;
  }

  Future<void> setVolume(double volume) => _player.setVolume(volume);

  Future<void> setAppRepeatMode(app_player.AppRepeatMode mode) async {
    _repeatMode = mode;
    await _player.setLoopMode(_loopModeFor(mode));
    playbackState.add(
      playbackState.value.copyWith(
        repeatMode: _audioServiceRepeatMode(mode),
      ),
    );
  }

  @override
  Future<void> stop() => _player.stop();

  @override
  Future<void> onTaskRemoved() async => stop();

  // ── Helpers ───────────────────────────────────────────────────────────────

  MediaItem _mediaItemForIndex(int index, {Duration? duration}) {
    final item = queue.value[index];
    return item.copyWith(
      duration: duration ?? _player.duration ?? item.duration,
    );
  }

  MediaItem _withNotificationDuration(MediaItem item) {
    return item.duration == null
        ? item.copyWith(duration: _durationFromExtras(item))
        : item;
  }

  Duration? _durationFromExtras(MediaItem item) {
    final value = item.extras?['durationMs'];
    if (value == null) return null;

    if (value is int && value > 0) {
      return Duration(milliseconds: value);
    }

    if (value is num && value > 0) {
      return Duration(milliseconds: value.round());
    }

    final parsed = int.tryParse(value.toString());
    if (parsed == null || parsed <= 0) return null;

    return Duration(milliseconds: parsed);
  }

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

  LoopMode _loopModeFor(app_player.AppRepeatMode mode) {
    switch (mode) {
      case app_player.AppRepeatMode.off:
        return LoopMode.off;
      case app_player.AppRepeatMode.one:
        return LoopMode.one;
      case app_player.AppRepeatMode.all:
        return LoopMode.all;
    }
  }

  AudioServiceRepeatMode _audioServiceRepeatMode(
    app_player.AppRepeatMode mode,
  ) {
    switch (mode) {
      case app_player.AppRepeatMode.off:
        return AudioServiceRepeatMode.none;
      case app_player.AppRepeatMode.one:
        return AudioServiceRepeatMode.one;
      case app_player.AppRepeatMode.all:
        return AudioServiceRepeatMode.all;
    }
  }
}

// ─── Silent fallback ──────────────────────────────────────────────────────────

class _SilentAudioSource extends StreamAudioSource {
  _SilentAudioSource(this.item) : super(tag: item);

  final MediaItem item;

  @override
  Future<StreamAudioResponse> request([int? start, int? end]) async {
    final bytes = <int>[];

    return StreamAudioResponse(
      sourceLength: 0,
      contentLength: 0,
      offset: 0,
      stream: Stream.value(bytes),
      contentType: 'audio/mpeg',
    );
  }
}
