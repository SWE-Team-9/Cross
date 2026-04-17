import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class PlayerUIState {
  final PlayerState playerState;
  final Track? currentTrack;
  final bool isFullScreen;
  final Set<String> playedTrackIds;

  // 🔥 NEW
  final bool showMiniPlayer;

  const PlayerUIState({
    required this.playerState,
    this.currentTrack,
    this.isFullScreen = false,
    this.playedTrackIds = const {},
    this.showMiniPlayer = true,
  });

  PlayerUIState copyWith({
    PlayerState? playerState,
    Track? currentTrack,
    bool? isFullScreen,
    Set<String>? playedTrackIds,
    bool? showMiniPlayer,
  }) {
    return PlayerUIState(
      playerState: playerState ?? this.playerState,
      currentTrack: currentTrack ?? this.currentTrack,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      playedTrackIds: playedTrackIds ?? this.playedTrackIds,
      showMiniPlayer: showMiniPlayer ?? this.showMiniPlayer,
    );
  }

  bool get isPlaying => playerState.status == PlayerStatus.playing;
  bool get isLoading => playerState.status == PlayerStatus.loading;
  bool get isBuffering => playerState.status == PlayerStatus.buffering;
  Duration get position => playerState.position;
  Duration? get duration => playerState.duration;
  double get volume => playerState.volume;
  List<Track> get queue {
    if (playerState.queue.isNotEmpty) return playerState.queue;
    final track = currentTrack;
    return track == null ? const <Track>[] : <Track>[track];
  }

  int get currentIndex {
    final tracks = queue;
    if (tracks.isEmpty) return -1;

    final track = currentTrack;
    if (track != null) {
      final index = tracks.indexWhere((item) => item.id == track.id);
      if (index >= 0) return index;
    }

    final index = playerState.currentIndex;
    return index >= 0 && index < tracks.length ? index : 0;
  }

  bool wasPlayed(String trackId) => playedTrackIds.contains(trackId);
}
