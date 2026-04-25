import 'track.dart'; // 🔥 ADD THIS

enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

enum AppRepeatMode {
  off,
  one,
  all,
}

class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration? duration;
  final String? errorMessage;
  final String? currentTrackId;

  // 🔥 NEW
  final List<Track> queue;
  final int currentIndex;
  final String? source;
  final double volume;
  final AppRepeatMode repeatMode;

  const PlayerState({
    required this.status,
    required this.position,
    this.duration,
    this.errorMessage,
    this.currentTrackId,

    // 🔥 DEFAULTS (THIS FIXES YOUR ERROR)
    this.queue = const [],
    this.currentIndex = 0,
    this.source,
    this.volume = 1.0,
    this.repeatMode = AppRepeatMode.off,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    String? currentTrackId,
    List<Track>? queue,
    int? currentIndex,
    String? source,
    double? volume,
    AppRepeatMode? repeatMode,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      currentTrackId: currentTrackId ?? this.currentTrackId,
      queue: queue ?? this.queue,
      currentIndex: currentIndex ?? this.currentIndex,
      source: source ?? this.source,
      volume: volume ?? this.volume,
      repeatMode: repeatMode ?? this.repeatMode,
    );
  }
}
