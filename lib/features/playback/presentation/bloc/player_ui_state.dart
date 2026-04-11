import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class PlayerUIState {
  final PlayerState playerState;
  final Track? currentTrack;
  final bool isFullScreen;

  const PlayerUIState({
    required this.playerState,
    this.currentTrack,
    this.isFullScreen = false,
  });

  PlayerUIState copyWith({
    PlayerState? playerState,
    Track? currentTrack,
    bool? isFullScreen,
  }) {
    return PlayerUIState(
      playerState: playerState ?? this.playerState,
      currentTrack: currentTrack ?? this.currentTrack,
      isFullScreen: isFullScreen ?? this.isFullScreen,
    );
  }

  bool get isPlaying => playerState.status == PlayerStatus.playing;

  bool get isLoading => playerState.status == PlayerStatus.loading;

  bool get isBuffering => playerState.status == PlayerStatus.buffering;

  Duration get position => playerState.position;

  Duration? get duration => playerState.duration;
}
