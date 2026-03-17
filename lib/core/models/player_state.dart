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

  const PlayerState({
    required this.status,
    required this.position,
    this.duration,
    this.errorMessage,
  });

  PlayerState copyWith({
    PlayerStatus? status,
    Duration? position,
    Duration? duration,
    String? errorMessage,
  }) {
    return PlayerState(
      status: status ?? this.status,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}
