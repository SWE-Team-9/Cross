import 'package:flutter/material.dart';

class PlayerSeekBar extends StatelessWidget {
  final Duration position;
  final Duration? duration;
  final Function(Duration) onSeek;

  const PlayerSeekBar({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration?.inSeconds ?? 0;
    final current = position.inSeconds.clamp(0, total);

    return Column(
      children: [
        Slider(
          value: current.toDouble(),
          max: total > 0 ? total.toDouble() : 1,
          activeColor: const Color(0xFFFF5500),
          inactiveColor: Colors.white24,
          onChanged: (value) {
            onSeek(Duration(seconds: value.toInt()));
          },
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _format(position),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            Text(
              _format(duration ?? Duration.zero),
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
          ],
        ),
      ],
    );
  }

  String _format(Duration d) {
    final minutes = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return "$minutes:$seconds";
  }
}
