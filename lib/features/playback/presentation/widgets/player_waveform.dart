import 'package:flutter/material.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

class PlayerWaveform extends StatelessWidget {
  final Duration position;
  final Duration? duration;
  final Function(Duration) onSeek;
  final List<int> commentTimestampsSeconds;
  final WaveformData? waveformData;

  const PlayerWaveform({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    this.waveformData,
    this.commentTimestampsSeconds = const [],
  });

  @override
  Widget build(BuildContext context) {
    final total = duration?.inMilliseconds ?? 1;
    final current = position.inMilliseconds.clamp(0, total);
    final progress = total == 0 ? 0.0 : current / total;

    final bars = waveformData?.resample(120) ?? [];
    if (bars.isEmpty) {
      return const SizedBox(
        height: 72,
        child: Center(
          child: Text(
            'Loading waveform...',
            style: TextStyle(color: Colors.white38),
          ),
        ),
      );
    }

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
        child: Stack(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(bars.length, (index) {
                final barProgress = bars.isEmpty ? 0 : index / bars.length;
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
                            color: isPlayed
                                ? const Color(0xFFFF5500)
                                : Colors.white24,
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
            LayoutBuilder(
              builder: (context, constraints) {
                if (duration == null || duration!.inSeconds <= 0) {
                  return const SizedBox.shrink();
                }

                return Stack(
                  children: commentTimestampsSeconds.map((seconds) {
                    final ratio = (seconds / duration!.inSeconds)
                        .clamp(0.0, 1.0)
                        .toDouble();

                    return Positioned(
                      left: (constraints.maxWidth * ratio - 3)
                          .clamp(0.0, constraints.maxWidth - 6),
                      top: 4,
                      child: Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD166),
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.black, width: 1),
                        ),
                      ),
                    );
                  }).toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
