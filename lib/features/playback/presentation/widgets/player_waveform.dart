import 'package:flutter/material.dart';
import 'dart:math';

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

    // Deterministic fake waveform heights
    final rng = Random(42);
    final bars = List.generate(80, (i) {
      final base = 0.2 + rng.nextDouble() * 0.8;
      // Make it look more musical — peaks and valleys
      final wave = sin(i * 0.3) * 0.2;
      return (base + wave).clamp(0.15, 1.0);
    });

    return GestureDetector(
      onTapDown: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final width = box.size.width;
        final ratio = (localX / width).clamp(0.0, 1.0);
        final newPosition = Duration(milliseconds: (ratio * total).toInt());
        onSeek(newPosition);
      },
      onHorizontalDragUpdate: (details) {
        final box = context.findRenderObject() as RenderBox;
        final localX = details.localPosition.dx;
        final width = box.size.width;
        final ratio = (localX / width).clamp(0.0, 1.0);
        final newPosition = Duration(milliseconds: (ratio * total).toInt());
        onSeek(newPosition);
      },
      child: SizedBox(
        height: 72,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(bars.length, (index) {
            final barProgress = index / bars.length;
            final isPlayed = barProgress <= progress;
            final barHeight = bars[index] * 60;

            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 0.8),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Top half
                    Container(
                      height: barHeight * 0.65,
                      decoration: BoxDecoration(
                        color:
                            isPlayed ? const Color(0xFFFF5500) : Colors.white24,
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(1),
                        ),
                      ),
                    ),
                    const SizedBox(height: 1),
                    // Bottom reflection (mirrored, dimmer)
                    Container(
                      height: barHeight * 0.25,
                      decoration: BoxDecoration(
                        color: isPlayed
                            ? const Color(0xFFFF5500).withValues(alpha: 0.3)
                            : Colors.white12,
                        borderRadius: const BorderRadius.vertical(
                          bottom: Radius.circular(1),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}
