import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

class PlayerUIState {
  final PlayerState playerState;
  final Track? currentTrack;
  final bool isFullScreen;
  final Set<String> playedTrackIds;
  final WaveformData? waveform;

  // 🔥 NEW
  final bool showMiniPlayer;

  const PlayerUIState({
    required this.playerState,
    this.currentTrack,
    this.isFullScreen = false,
    this.playedTrackIds = const {},
    this.waveform, // ✅ ADDED
    this.showMiniPlayer = true,
  });

  PlayerUIState copyWith({
    PlayerState? playerState,
    Track? currentTrack,
    bool? isFullScreen,
    Set<String>? playedTrackIds,
    WaveformData? waveform, // ✅ ADDED
    bool? showMiniPlayer,
  }) {
    return PlayerUIState(
      playerState: playerState ?? this.playerState,
      currentTrack: currentTrack ?? this.currentTrack,
      isFullScreen: isFullScreen ?? this.isFullScreen,
      playedTrackIds: playedTrackIds ?? this.playedTrackIds,
      waveform: waveform ?? this.waveform, // ✅ ADDED
      showMiniPlayer: showMiniPlayer ?? this.showMiniPlayer,
    );
  }

  bool get isPlaying => playerState.status == PlayerStatus.playing;
  bool get isLoading => playerState.status == PlayerStatus.loading;
  bool get isBuffering => playerState.status == PlayerStatus.buffering;
  Duration get position => playerState.position;
  Duration? get duration => playerState.duration;
  double get volume => playerState.volume;
  AppRepeatMode get repeatMode => playerState.repeatMode;

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
