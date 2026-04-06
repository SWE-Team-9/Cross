import 'package:flutter/material.dart';

class PlayerControls extends StatelessWidget {
  final bool isPlaying;
  final Duration position;
  final Duration? duration;

  final VoidCallback onPlayPause;
  final Function(Duration) onSeek;

  const PlayerControls({
    super.key,
    required this.isPlaying,
    required this.onPlayPause,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  void _skipForward() {
    final newPosition = position + const Duration(seconds: 10);
    onSeek(newPosition);
  }

  void _skipBackward() {
    final newPosition = position - const Duration(seconds: 10);
    onSeek(newPosition < Duration.zero ? Duration.zero : newPosition);
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: _skipBackward,
          icon: const Icon(Icons.replay_10, color: Colors.white70, size: 28),
        ),
        const SizedBox(width: 20),
        GestureDetector(
          onTap: onPlayPause,
          child: Container(
            width: 70,
            height: 70,
            decoration: const BoxDecoration(
              color: Color(0xFFFF5500),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPlaying ? Icons.pause : Icons.play_arrow,
              size: 36,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(width: 20),
        IconButton(
          onPressed: _skipForward,
          icon: const Icon(Icons.forward_10, color: Colors.white70, size: 28),
        ),
      ],
    );
  }
}
