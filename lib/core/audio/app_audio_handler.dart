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

  Future<void> playTrack({
    required String url,
    required String title,
    required String artist,
    String? artworkUrl, // 🔥 NEW
  }) async {
    await _player.setUrl(url);

    // 🔥 SAFE artwork handling
    Uri? artUri;
    if (artworkUrl != null && artworkUrl.isNotEmpty) {
      try {
        artUri = Uri.parse(artworkUrl);
      } catch (_) {
        artUri = null;
      }
    }

    mediaItem.add(
      MediaItem(
        id: url,
        title: title,
        artist: artist,
        duration: _player.duration ?? Duration.zero,
        artUri: artUri,
      ),
    );

    await _player.play();
  }

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
}
