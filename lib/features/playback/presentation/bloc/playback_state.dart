import 'package:soundcloud_clone/core/models/track.dart';

class PlaybackState {
  final Track? currentTrack;
  final List<Track> queue;
  final bool isPlaying;
  final Duration position;
  final Duration? duration;
  final bool isAvailable;

  const PlaybackState({
    this.currentTrack,
    this.queue = const [],
    this.isPlaying = false,
    this.position = Duration.zero,
    this.duration,
    this.isAvailable = true,
  });

  PlaybackState copyWith({
    Track? currentTrack,
    List<Track>? queue,
    bool? isPlaying,
    Duration? position,
    Duration? duration,
    bool? isAvailable,
  }) {
    return PlaybackState(
      currentTrack: currentTrack ?? this.currentTrack,
      queue: queue ?? this.queue,
      isPlaying: isPlaying ?? this.isPlaying,
      position: position ?? this.position,
      duration: duration ?? this.duration,
      isAvailable: isAvailable ?? this.isAvailable,
    );
  }
}
