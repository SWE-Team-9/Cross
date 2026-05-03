import 'package:flutter/material.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

/// ScrollingWaveformV2 — Reimplemented with CustomPaint for robustness
/// ✅ No layout overflow issues (draws directly to canvas)
/// ✅ Drag to seek works smoothly
/// ✅ Playhead at center of screen
/// ✅ Comment markers with clipping
/// ✅ Paused line extends to end
class ScrollingWaveformV2 extends StatefulWidget {
  final Duration position;
  final Duration? duration;
  final WaveformData? waveformData;
  final List<int> commentTimestampsSeconds;
  final Function(Duration) onSeek;
  final bool isPlaying;

  const ScrollingWaveformV2({
    super.key,
    required this.position,
    required this.duration,
    required this.onSeek,
    required this.isPlaying,
    this.waveformData,
    this.commentTimestampsSeconds = const [],
  });

  @override
  State<ScrollingWaveformV2> createState() => _ScrollingWaveformV2State();
}

class _ScrollingWaveformV2State extends State<ScrollingWaveformV2> {
  double? _dragProgress;

  static const int _barCount = 180;
  static const double _barWidth = 3.0;
  static const double _barGap = 1.0;
  static const double _barSpacing = _barWidth + _barGap;
  static const double _waveformHeightFraction = 0.20;

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final waveformHeight =
        screenSize.height * _waveformHeightFraction;
    final maxBarHeight = waveformHeight * 0.85;
    const minBarHeight = 3.0;

    final totalMs = widget.duration?.inMilliseconds ?? 1;
    final currentMs = widget.position.inMilliseconds.clamp(0, totalMs);
    final progress =
        _dragProgress ?? (totalMs == 0 ? 0.0 : currentMs / totalMs);

    final rawBars =
        widget.waveformData?.resample(_barCount) ?? [];
    final bars = _normalizeBars(rawBars);

    final totalWaveWidth = _barCount * _barSpacing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _handleTapSeek(
        tapLocalX: d.localPosition.dx,
        screenWidth: screenSize.width,
        totalWaveWidth: totalWaveWidth,
        totalMs: totalMs,
      ),
      onHorizontalDragStart: (d) {
        setState(() => _dragProgress = progress);
      },
      onHorizontalDragUpdate: (d) {
        final deltaProgress = -(d.delta.dx / totalWaveWidth);
        final newProgress =
            ((_dragProgress ?? progress) + deltaProgress).clamp(0.0, 1.0);
        setState(() => _dragProgress = newProgress);
        widget.onSeek(Duration(milliseconds: (newProgress * totalMs).round()));
      },
      onHorizontalDragEnd: (_) {
        setState(() => _dragProgress = null);
      },
      onHorizontalDragCancel: () {
        setState(() => _dragProgress = null);
      },
      child: SizedBox(
        width: screenSize.width,
        height: waveformHeight,
        child: ClipRect(
          child: CustomPaint(
            painter: WaveformPainter(
              bars: bars,
              progress: progress,
              totalWaveWidth: totalWaveWidth,
              screenWidth: screenSize.width,
              waveformHeight: waveformHeight,
              maxBarHeight: maxBarHeight,
              minBarHeight: minBarHeight,
              isPlaying: widget.isPlaying,
              commentTimestamps: widget.commentTimestampsSeconds,
              duration: widget.duration,
            ),
            size: Size(screenSize.width, waveformHeight),
          ),
        ),
      ),
    );
  }

  void _handleTapSeek({
    required double tapLocalX,
    required double screenWidth,
    required double totalWaveWidth,
    required int totalMs,
  }) {
    // Calculate playhead X position (center of screen)
    final playheadX = screenWidth * 0.5;
    
    // Calculate waveform X position based on current progress
    final currentProgress =
        _dragProgress ?? (totalMs == 0 ? 0.0 : widget.position.inMilliseconds / totalMs);
    final waveformX = playheadX - (currentProgress * totalWaveWidth);
    
    // Get waveform coordinate from tap position
    final waveX = tapLocalX - waveformX;
    final ratio = (waveX / totalWaveWidth).clamp(0.0, 1.0);
    
    widget.onSeek(Duration(milliseconds: (ratio * totalMs).round()));
  }

  List<double> _normalizeBars(List<double> raw) {
    if (raw.isEmpty) {
      return List.generate(_barCount, (i) {
        return (0.3 + 0.5 * (0.5 + 0.4 * _pseudoRandom(i)))
            .clamp(0.15, 1.0);
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
}

// ════════════════════════════════════════════════════════════════════════════
// Waveform painter — draws everything to canvas
// ════════════════════════════════════════════════════════════════════════════

class WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final double totalWaveWidth;
  final double screenWidth;
  final double waveformHeight;
  final double maxBarHeight;
  final double minBarHeight;
  final bool isPlaying;
  final List<int> commentTimestamps;
  final Duration? duration;

  static const double _barWidth = 3.0;
  static const double _barSpacing = 4.0;
  static const Color _playedColor = Color(0xFFFF5500);
  static const Color _unplayedColor = Colors.white;
  static const Color _playedFadeColor = Color(0xFFFF5500);

  WaveformPainter({
    required this.bars,
    required this.progress,
    required this.totalWaveWidth,
    required this.screenWidth,
    required this.waveformHeight,
    required this.maxBarHeight,
    required this.minBarHeight,
    required this.isPlaying,
    required this.commentTimestamps,
    required this.duration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final playheadX = screenWidth * 0.5;
    final centerY = waveformHeight / 2;

    // Calculate waveform position (scrolls so playhead stays at center)
    final waveformX = playheadX - (progress * totalWaveWidth);

    if (isPlaying) {
      _drawWaveformBars(canvas, waveformX, centerY);
    } else {
      _drawPausedLine(canvas, waveformX, centerY);
    }

    // Draw comment markers
    _drawCommentMarkers(canvas, waveformX, centerY);

    // Draw playhead
    _drawPlayhead(canvas, playheadX, centerY);
  }

  void _drawWaveformBars(Canvas canvas, double waveformX, double centerY) {
    final barPaint = Paint();
    final barFadePaint = Paint();

    for (int i = 0; i < bars.length; i++) {
      final barX = waveformX + (i * _barSpacing);
      
      // Skip bars outside visible area
      if (barX + _barWidth < 0 || barX > screenWidth) {
        continue;
      }

      final frac = i / bars.length;
      final isPlayed = frac <= progress;
      final dist = (frac - progress).abs();
      final isNear = dist < (2 / bars.length);
      
      // Height multiplier for bars near playhead
      final mult = isNear
          ? (1.0 + (1.0 - dist / (2 / bars.length)) * 0.10)
          : 1.0;

      final barHeight = (minBarHeight +
              bars[i] * (maxBarHeight - minBarHeight) * mult)
          .clamp(minBarHeight, maxBarHeight);

      // Top bar
      barPaint.color =
          isPlayed ? _playedColor : _unplayedColor.withValues(alpha: 0.55);
      canvas.drawRect(
        Rect.fromLTWH(
          barX,
          centerY - (barHeight * 0.68) / 2,
          _barWidth,
          barHeight * 0.68,
        ),
        barPaint,
      );

      // Bottom bar
      barFadePaint.color = isPlayed
          ? _playedFadeColor.withValues(alpha: 0.35)
          : _unplayedColor.withValues(alpha: 0.18);
      canvas.drawRect(
        Rect.fromLTWH(
          barX,
          centerY + (barHeight * 0.22) / 2 - barHeight * 0.22,
          _barWidth,
          barHeight * 0.22,
        ),
        barFadePaint,
      );
    }
  }

  void _drawPausedLine(Canvas canvas, double waveformX, double centerY) {
    final playedWidth = (progress * totalWaveWidth).clamp(0.0, totalWaveWidth);
    final playedPaint = Paint()..color = _playedColor;
    final unplayedPaint = Paint()
      ..color = _unplayedColor.withValues(alpha: 0.30);

    // Draw played segment
    canvas.drawRect(
      Rect.fromLTWH(
        waveformX,
        centerY - 1,
        playedWidth,
        2,
      ),
      playedPaint,
    );

    // Draw unplayed segment
    canvas.drawRect(
      Rect.fromLTWH(
        waveformX + playedWidth,
        centerY - 1,
        totalWaveWidth - playedWidth,
        2,
      ),
      unplayedPaint,
    );

    // Draw dot at playhead
    final dotPaint = Paint()..color = _playedColor;
    canvas.drawCircle(Offset(waveformX + playedWidth, centerY), 5, dotPaint);
  }

  void _drawCommentMarkers(Canvas canvas, double waveformX, double centerY) {
    if (duration == null || duration!.inSeconds == 0) return;

    final durationSeconds = duration!.inSeconds.toDouble();
    final markerPaint = Paint()
      ..color = const Color(0xFFFFD166)
      ..style = PaintingStyle.fill;
    final borderPaint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (final seconds in commentTimestamps) {
      final ratio = (seconds / durationSeconds).clamp(0.0, 1.0);
      final markerX = waveformX + (ratio * totalWaveWidth);

      // Skip markers outside visible area
      if (markerX < -10 || markerX > screenWidth + 10) {
        continue;
      }

      // Draw marker circle
      canvas.drawCircle(Offset(markerX, centerY - waveformHeight / 2 + 12),
          4, markerPaint);
      canvas.drawCircle(Offset(markerX, centerY - waveformHeight / 2 + 12),
          4, borderPaint);
    }
  }

  void _drawPlayhead(Canvas canvas, double playheadX, double centerY) {
    final playheadPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2;
    
    final glowPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..strokeWidth = 1
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    // Draw glow
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, waveformHeight),
      glowPaint,
    );

    // Draw playhead line
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, waveformHeight),
      playheadPaint,
    );
  }

  @override
  bool shouldRepaint(WaveformPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.isPlaying != isPlaying ||
        oldDelegate.bars != bars;
  }
}
