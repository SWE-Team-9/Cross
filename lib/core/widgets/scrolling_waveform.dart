import 'package:flutter/material.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

/// ScrollingWaveform — fixed version
/// ✅ Waveform drag works while playing AND paused
/// ✅ Drag direction fixed: drag left = forward, drag right = backward
/// ✅ No freeze/stutter when dragging then releasing (no snap-back)
/// ✅ Paused line extends full width to end of track
/// ✅ No overflow on screen edges
class ScrollingWaveform extends StatefulWidget {
  final Duration position;
  final Duration? duration;
  final WaveformData? waveformData;
  final List<int> commentTimestampsSeconds;
  final Function(Duration) onSeek;
  final bool isPlaying;

  const ScrollingWaveform({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.isPlaying,
    this.waveformData,
    this.commentTimestampsSeconds = const [],
  });

  // ── Layout constants ───────────────────────────────────────────────────────
  static const int _barCount = 180;
  static const double _barWidth = 3.0;
  static const double _barGap = 1.0;
  static const double _totalBarStep = _barWidth + _barGap;
  static const double _waveformHeightFraction = 0.20;

  @override
  State<ScrollingWaveform> createState() => _ScrollingWaveformState();
}

class _ScrollingWaveformState extends State<ScrollingWaveform> {
  // Drag state: progress captured at drag-start, updated each drag update.
  double? _dragProgress;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final waveformHeight =
        screenSize.height * ScrollingWaveform._waveformHeightFraction;
    final maxBarHeight = waveformHeight * 0.85;
    const minBarHeight = 3.0;

    final totalMs = widget.duration?.inMilliseconds ?? 1;
    final currentMs = widget.position.inMilliseconds.clamp(0, totalMs);

    // _dragProgress overrides BLoC progress during active drag so the waveform
    // follows the finger immediately without waiting for a seek round-trip.
    final progress =
        _dragProgress ?? (totalMs == 0 ? 0.0 : currentMs / totalMs);

    final rawBars =
        widget.waveformData?.resample(ScrollingWaveform._barCount) ?? [];
    final bars = _normalizeBars(rawBars);

    final double totalWaveWidth =
        ScrollingWaveform._barCount * ScrollingWaveform._totalBarStep;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth =
            constraints.maxWidth.isFinite && constraints.maxWidth > 0
                ? constraints.maxWidth
                : screenSize.width;

        // Playhead sits at horizontal centre of the available space.
        final double playheadX = availableWidth * 0.5;

        // translateX positions the waveform so the current-progress bar aligns
        // with the playhead.
        final double rawTranslateX = playheadX - (progress * totalWaveWidth);
        final double minTranslate = availableWidth - totalWaveWidth - playheadX;
        final double maxTranslate = playheadX;
        final double translateX = rawTranslateX.clamp(minTranslate, maxTranslate);

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          // ── Tap → instant seek ───────────────────────────────────────────
          onTapDown: (d) => _handleTapSeek(
            tapLocalX: d.localPosition.dx,
            translateX: translateX,
            totalWaveWidth: totalWaveWidth,
            totalMs: totalMs,
          ),
          // ── Drag → continuous seek, waveform follows finger 1-to-1 ──────
          onHorizontalDragStart: (d) {
            // Capture current progress so we can accumulate from here.
            setState(() => _dragProgress = progress);
          },
          onHorizontalDragUpdate: (d) {
            // Convert pixel delta to progress delta.
            // Dragging LEFT (negative dx) = moving FORWARD → positive progress.
            // Dragging RIGHT (positive dx) = moving BACKWARD → negative progress.
            final deltaProgress = -(d.delta.dx / totalWaveWidth);
            final newProgress =
                ((_dragProgress ?? progress) + deltaProgress).clamp(0.0, 1.0);
            setState(() => _dragProgress = newProgress);
            // Fire seek so audio position updates while dragging.
            widget.onSeek(Duration(milliseconds: (newProgress * totalMs).round()));
          },
          onHorizontalDragEnd: (_) {
            // Seek is already committed during drag; just clear the override.
            setState(() => _dragProgress = null);
          },
          onHorizontalDragCancel: () {
            setState(() => _dragProgress = null);
          },
          child: SizedBox(
            width: availableWidth,
            height: waveformHeight,
            // ClipRect prevents bars from rendering outside the widget bounds.
            child: ClipRect(
              child: Stack(
                clipBehavior: Clip.hardEdge,
                children: [
                  // ── Waveform bars (playing) OR flat line (paused) ───────
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 350),
                    switchInCurve: Curves.easeOut,
                    switchOutCurve: Curves.easeIn,
                    transitionBuilder: (child, anim) =>
                        FadeTransition(opacity: anim, child: child),
                    child: widget.isPlaying
                        ? _WaveformBars(
                            key: const ValueKey('wave'),
                            bars: bars,
                            progress: progress,
                            translateX: translateX,
                            totalWaveWidth: totalWaveWidth,
                            screenWidth: availableWidth,
                            waveformHeight: waveformHeight,
                            maxBarHeight: maxBarHeight,
                            minBarHeight: minBarHeight,
                          )
                        : _PausedLine(
                            key: const ValueKey('line'),
                            progress: progress,
                            translateX: translateX,
                            totalWaveWidth: totalWaveWidth,
                            screenWidth: availableWidth,
                            waveformHeight: waveformHeight,
                          ),
                  ),

                  // ── Playhead ───────────────────────────────────────────
                  Positioned(
                    left: playheadX - 1,
                    top: 0,
                    bottom: 0,
                    child: _PlayheadWithTime(
                      position: widget.position,
                      duration: widget.duration,
                      isPlaying: widget.isPlaying,
                      waveformHeight: waveformHeight,
                    ),
                  ),

                  // ── Comment markers ───────────────────────────────────
                  if (widget.duration != null &&
                      widget.duration!.inSeconds > 0 &&
                      bars.isNotEmpty)
                    ..._buildCommentMarkers(
                      translateX: translateX,
                      totalWaveWidth: totalWaveWidth,
                      durationSeconds: widget.duration!.inSeconds,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleTapSeek({
    required double tapLocalX,
    required double translateX,
    required double totalWaveWidth,
    required int totalMs,
  }) {
    final waveX = tapLocalX - translateX;
    final ratio = (waveX / totalWaveWidth).clamp(0.0, 1.0);
    widget.onSeek(Duration(milliseconds: (ratio * totalMs).round()));
  }

  List<double> _normalizeBars(List<double> raw) {
    if (raw.isEmpty) {
      return List.generate(ScrollingWaveform._barCount, (i) {
        return (0.3 + 0.5 * (0.5 + 0.4 * _pseudoRandom(i))).clamp(0.15, 1.0);
      });
    }
    final maxVal = raw.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return List.filled(raw.length, 0.3);
    return raw.map((v) => (v / maxVal).clamp(0.05, 1.0)).toList();
  }

  double _pseudoRandom(int seed) {
    final x = (seed * 9301 + 49297) % 233280;
    return x / 233280.0;
  }

  List<Widget> _buildCommentMarkers({
    required double translateX,
    required double totalWaveWidth,
    required int durationSeconds,
  }) {
    final screenSize = MediaQuery.of(context).size;
    return widget.commentTimestampsSeconds.map((seconds) {
      final ratio = (seconds / durationSeconds).clamp(0.0, 1.0);
      final markerX = translateX + ratio * totalWaveWidth;
      // Clamp marker position to stay within screen bounds
      final clampedMarkerX = markerX.clamp(-4.0, screenSize.width);
      return Positioned(
        left: clampedMarkerX - 4,
        top: 6,
        child: Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: const Color(0xFFFFD166),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.black, width: 1.2),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFFD166).withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Waveform bars — playing state
// ════════════════════════════════════════════════════════════════════════════

class _WaveformBars extends StatelessWidget {
  final List<double> bars;
  final double progress;
  final double translateX;
  final double totalWaveWidth;
  final double screenWidth;
  final double waveformHeight;
  final double maxBarHeight;
  final double minBarHeight;

  static const double _barWidth = ScrollingWaveform._barWidth;
  static const double _totalBarStep = ScrollingWaveform._totalBarStep;
  static const double _barGap = ScrollingWaveform._barGap;

  const _WaveformBars({
    super.key,
    required this.bars,
    required this.progress,
    required this.translateX,
    required this.totalWaveWidth,
    required this.screenWidth,
    required this.waveformHeight,
    required this.maxBarHeight,
    required this.minBarHeight,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: SizedBox(
        width: screenWidth,
        height: waveformHeight,
        child: Transform.translate(
          offset: Offset(translateX, 0),
          child: Container(
            width: totalWaveWidth,
            height: waveformHeight,
            clipBehavior: Clip.hardEdge,
            decoration: const BoxDecoration(),
            child: Row(
              mainAxisSize: MainAxisSize.max,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: List.generate(bars.length, (i) {
              final frac = i / bars.length;
              final isPlayed = frac <= progress;
              final dist = (frac - progress).abs();
              final isNear = dist < (2 / bars.length);
              final mult = isNear
                  ? (1.0 + (1.0 - dist / (2 / bars.length)) * 0.10)
                  : 1.0;
              final totalH = (minBarHeight +
                      bars[i] * (maxBarHeight - minBarHeight) * mult)
                  .clamp(minBarHeight, maxBarHeight);

              return SizedBox(
                width: _totalBarStep,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: _barGap / 2),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: _barWidth,
                        height: totalH * 0.68,
                        decoration: BoxDecoration(
                          color: isPlayed
                              ? const Color(0xFFFF5500)
                              : Colors.white.withValues(alpha: 0.55),
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(1.5)),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Container(
                        width: _barWidth,
                        height: totalH * 0.22,
                        decoration: BoxDecoration(
                          color: isPlayed
                              ? const Color(0xFFFF5500).withValues(alpha: 0.35)
                              : Colors.white.withValues(alpha: 0.18),
                          borderRadius: const BorderRadius.vertical(
                              bottom: Radius.circular(1.5)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Paused line — fixed to extend correctly to end of track
// ════════════════════════════════════════════════════════════════════════════

class _PausedLine extends StatelessWidget {
  final double progress;
  final double translateX;
  final double totalWaveWidth;
  final double screenWidth;
  final double waveformHeight;

  const _PausedLine({
    super.key,
    required this.progress,
    required this.translateX,
    required this.totalWaveWidth,
    required this.screenWidth,
    required this.waveformHeight,
  });

  @override
  Widget build(BuildContext context) {
    final playedWidth = (progress * totalWaveWidth).clamp(0.0, totalWaveWidth);
    final remainingWidth =
        (totalWaveWidth - playedWidth).clamp(0.0, totalWaveWidth);
    final midY = waveformHeight / 2;

    return SizedBox(
      width: screenWidth,
      height: waveformHeight,
      child: Transform.translate(
        offset: Offset(translateX, 0),
        child: Container(
          width: totalWaveWidth,
          height: waveformHeight,
          clipBehavior: Clip.hardEdge,
          decoration: const BoxDecoration(),
          child: Stack(
            children: [
              // Played segment (orange)
              Positioned(
                left: 0,
                top: midY - 1,
                child: Container(
                  width: playedWidth,
                  height: 2,
                  color: const Color(0xFFFF5500),
                ),
              ),
              // Remaining segment (white translucent)
              Positioned(
                left: playedWidth,
                top: midY - 1,
                child: Container(
                  width: remainingWidth,
                  height: 2,
                  color: Colors.white.withValues(alpha: 0.30),
                ),
              ),
              // Dot at playhead
              Positioned(
                left: (playedWidth - 5).clamp(0.0, totalWaveWidth - 10),
                top: midY - 5,
                child: Container(
                  width: 10,
                  height: 10,
                  decoration: const BoxDecoration(
                    color: Color(0xFFFF5500),
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Playhead + time label
// ════════════════════════════════════════════════════════════════════════════

class _PlayheadWithTime extends StatelessWidget {
  final Duration position;
  final Duration? duration;
  final bool isPlaying;
  final double waveformHeight;

  const _PlayheadWithTime({
    required this.position,
    required this.duration,
    required this.isPlaying,
    required this.waveformHeight,
  });

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    const labelWidth = 88.0;
    const labelHeight = 20.0;

    return SizedBox(
      width: 2,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(
            top: isPlaying ? 6 : 0,
            bottom: isPlaying ? 6 : 0,
            child: Container(
              width: 2,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(1),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.7),
                    blurRadius: 6,
                  ),
                ],
              ),
            ),
          ),
          if (!isPlaying)
            Positioned(
              top: -(labelHeight + 4),
              left: -(labelWidth / 2),
              child: Container(
                width: labelWidth,
                height: labelHeight,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.75),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${_fmt(position)} | ${_fmt(duration ?? Duration.zero)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
