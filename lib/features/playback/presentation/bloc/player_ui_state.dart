import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class PlayerUIState {
  final PlayerState playerState;
  final Track? currentTrack;
  final bool isFullScreen;
  final Set<String> playedTrackIds; // ← الأغاني اللي اتشغلت

  const PlayerUIState({
    required this.playerState,
    this.currentTrack,
    this.isFullScreen = false,
    this.playedTrackIds = const {},
  });

  PlayerUIState copyWith({
    PlayerState? playerState,
    Track? currentTrack,
    bool? isFullScreen,
    Set<String>? playedTrackIds,
  }) {
    return PlayerUIState(
      playerState: playerState ?? this.playerState,
      currentTrack: currentTrack ?? this.currentTrack,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      playedTrackIds: playedTrackIds ?? this.playedTrackIds,
    );
  }

  bool get isPlaying => playerState.status == PlayerStatus.playing;
  bool get isLoading => playerState.status == PlayerStatus.loading;
  bool get isBuffering => playerState.status == PlayerStatus.buffering;
  Duration get position => playerState.position;
  Duration? get duration => playerState.duration;

  // هل الأغنية دي اتشغلت قبل كده؟
  bool wasPlayed(String trackId) => playedTrackIds.contains(trackId);
}