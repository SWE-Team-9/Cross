import 'package:flutter/material.dart';

class PlayerWaveform extends StatelessWidget {
  final Duration position;
  final Duration? duration;
  final Function(Duration) onSeek;

  const PlayerWaveform({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
  });

  @override
  Widget build(BuildContext context) {
    final total = duration?.inMilliseconds ?? 1;
    final current = position.inMilliseconds.clamp(0, total);

    final progress = total == 0 ? 0.0 : current / total;

    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final width = box.size.width;

        final ratio = (localX / width).clamp(0.0, 1.0);
        final newPosition = Duration(milliseconds: (ratio * total).toInt());

        onSeek(newPosition);
      },
      child: SizedBox(
        height: 80,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(60, (index) {
            final barProgress = index / 60;

            final isActive = barProgress <= progress;

            final height = (10 + (index % 10) * 3).toDouble();

            return Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 1),
                height: height,
                decoration: BoxDecoration(
                  color: isActive ? const Color(0xFFFF5500) : Colors.white24,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
