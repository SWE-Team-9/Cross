import '../models/player_state.dart';
import '../models/track.dart';

abstract class AudioPlayerService {
  /// Stream of the current player state
  Stream<PlayerState> get playerStateStream;

  /// Play audio from a URL
  Future<void> play(Track track);

  /// Pause playback
  Future<void> pause();

  /// Stop playback
  Future<void> stop();

  /// Seek to a position in the track
  Future<void> seek(Duration position);

  /// Dispose resources
  Future<void> dispose();
}
