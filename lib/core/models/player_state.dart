enum PlayerStatus {
  idle,
  loading,
  playing,
  paused,
  buffering,
  completed,
  error,
}

class PlayerState {
  final PlayerStatus status;
  final Duration position;
  final Duration? duration;
  final String? errorMessage;
  final String? currentTrackId;

  const PlayerState({
    required this.status,
    required this.position,
    this.duration,
    this.errorMessage,
    this.currentTrackId,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
    String? currentTrackId,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
      currentTrackId: currentTrackId ?? this.currentTrackId,
    );
  }
}
