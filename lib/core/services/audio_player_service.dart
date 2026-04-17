import '../models/player_state.dart';
import '../models/track.dart';

abstract class AudioPlayerService {
  /// Stream of the current player state
  Stream<PlayerState> get playerStateStream;

  /// Play audio from a URL
  Future<void> play(Track track);

  Future<void> playFromContext({
    required List<Track> tracks,
    required int startIndex,
    required String source,
  });

  /// Pause playback
  Future<void> pause();

  Future<void> resume();

  /// Stop playback
  Future<void> stop();

  /// Seek to a position in the track
  Future<void> seek(Duration position);

  /// Sets playback output volume.
  ///
  /// Expected range is 0.0 (mute) to 1.0 (max).
  Future<void> setVolume(double volume);

  /// Current playback volume in the 0.0..1.0 range.
  double get currentVolume;

  /// Dispose resources
  Future<void> dispose();
}
