import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class PlayerUIState {
  final PlayerState playerState;
  final Track? currentTrack;

  const PlayerUIState({
    required this.playerState,
    this.currentTrack,
  });

  PlayerUIState copyWith({
    PlayerState? playerState,
    Track? currentTrack,
  }) {
    return PlayerUIState(
      playerState: playerState ?? this.playerState,
      currentTrack: currentTrack ?? this.currentTrack,
    );
  }

  bool get isPlaying => playerState.status == PlayerStatus.playing;

  bool get isLoading => playerState.status == PlayerStatus.loading;

  bool get isBuffering => playerState.status == PlayerStatus.buffering;

  Duration get position => playerState.position;

  Duration? get duration => playerState.duration;
}
