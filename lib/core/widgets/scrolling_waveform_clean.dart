import 'package:flutter/material.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';

// ════════════════════════════════════════════════════════════════════════════
// Waveform Constants
// ════════════════════════════════════════════════════════════════════════════

const int _waveBarCount = 180;
const double _waveBarWidth = 3.0;
const double _waveBarGap = 1.0;
const double _waveBarSpacing = _waveBarWidth + _waveBarGap;
const double _waveHeightFraction = 0.20;
const double _waveMinBarHeight = 3.0;

const Color _wavePlayedColor = Color(0xFFFF5500);
const Color _waveUnplayedColor = Colors.white;
const Color _waveMarkerColor = Color(0xFFFFD166);

// ════════════════════════════════════════════════════════════════════════════
// ScrollingWaveformV2 Widget
// ════════════════════════════════════════════════════════════════════════════

/// High-performance waveform visualization using CustomPaint.
/// 
/// Handles audio visualization with no layout overflow issues by rendering
/// directly to canvas. Supports drag-to-seek, tap-to-seek, and displays
/// comment markers with a centered playhead.
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

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final waveformHeight = screenSize.height * _waveHeightFraction;
    final maxBarHeight = waveformHeight * 0.85;

    final totalMs = widget.duration?.inMilliseconds ?? 1;
    final currentMs = widget.position.inMilliseconds.clamp(0, totalMs);
    final progress =
        _dragProgress ?? (totalMs == 0 ? 0.0 : currentMs / totalMs);

    final bars = _getBars();
    final totalWaveWidth = _waveBarCount * _waveBarSpacing;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (d) => _handleTapSeek(d.localPosition.dx, screenSize.width,
          totalWaveWidth, totalMs),
      onHorizontalDragStart: (d) => setState(() => _dragProgress = progress),
      onHorizontalDragUpdate: (d) =>
          _handleDragUpdate(d, progress, totalWaveWidth, totalMs),
      onHorizontalDragEnd: (_) => setState(() => _dragProgress = null),
      onHorizontalDragCancel: () => setState(() => _dragProgress = null),
      child: SizedBox(
        width: screenSize.width,
        height: waveformHeight,
        child: ClipRect(
          child: CustomPaint(
            painter: _WaveformPainter(
              bars: bars,
              progress: progress,
              totalWaveWidth: totalWaveWidth,
              screenWidth: screenSize.width,
              waveformHeight: waveformHeight,
              maxBarHeight: maxBarHeight,
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

  List<double> _getBars() {
    final rawBars = widget.waveformData?.resample(_waveBarCount) ?? [];
    if (rawBars.isEmpty) {
      return List.generate(_waveBarCount, (i) {
        return (0.3 + 0.5 * (0.5 + 0.4 * _pseudoRandom(i)))
            .clamp(0.15, 1.0);
      });
    }

    final maxVal = rawBars.reduce((a, b) => a > b ? a : b);
    if (maxVal <= 0) return List.filled(rawBars.length, 0.3);

    return rawBars.map((v) => (v / maxVal).clamp(0.05, 1.0)).toList();
  }

  void _handleTapSeek(
      double tapLocalX, double screenWidth, double totalWaveWidth, int totalMs) {
    final playheadX = screenWidth * 0.5;
    final currentProgress = _dragProgress ??
        (totalMs == 0 ? 0.0 : widget.position.inMilliseconds / totalMs);
    final waveformX = playheadX - (currentProgress * totalWaveWidth);
    final waveX = tapLocalX - waveformX;
    final ratio = (waveX / totalWaveWidth).clamp(0.0, 1.0);

    widget.onSeek(Duration(milliseconds: (ratio * totalMs).round()));
  }

  void _handleDragUpdate(DragUpdateDetails d, double progress,
      double totalWaveWidth, int totalMs) {
    final deltaProgress = -(d.delta.dx / totalWaveWidth);
    final newProgress =
        ((_dragProgress ?? progress) + deltaProgress).clamp(0.0, 1.0);
    setState(() => _dragProgress = newProgress);
    widget.onSeek(Duration(milliseconds: (newProgress * totalMs).round()));
  }

  double _pseudoRandom(int seed) {
    final x = (seed * 9301 + 49297) % 233280;
    return x / 233280.0;
  }
}

// ════════════════════════════════════════════════════════════════════════════
// Waveform Painter
// ════════════════════════════════════════════════════════════════════════════

class _WaveformPainter extends CustomPainter {
  final List<double> bars;
  final double progress;
  final double totalWaveWidth;
  final double screenWidth;
  final double waveformHeight;
  final double maxBarHeight;
  final bool isPlaying;
  final List<int> commentTimestamps;
  final Duration? duration;

  _WaveformPainter({
    required this.bars,
    required this.progress,
    required this.totalWaveWidth,
    required this.screenWidth,
    required this.waveformHeight,
    required this.maxBarHeight,
    required this.isPlaying,
    required this.commentTimestamps,
    required this.duration,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final playheadX = screenWidth * 0.5;
    final centerY = waveformHeight / 2;
    final waveformX = playheadX - (progress * totalWaveWidth);

    if (isPlaying) {
      _drawBars(canvas, waveformX, centerY);
    } else {
      _drawTimeline(canvas, waveformX, centerY);
    }

    _drawMarkers(canvas, waveformX, centerY);
    _drawPlayhead(canvas, playheadX);
  }

  void _drawBars(Canvas canvas, double waveformX, double centerY) {
    for (int i = 0; i < bars.length; i++) {
      final barX = waveformX + (i * _waveBarSpacing);

      if (barX + _waveBarWidth < 0 || barX > screenWidth) continue;

      final frac = i / bars.length;
      final isPlayed = frac <= progress;
      final dist = (frac - progress).abs();
      final isNear = dist < (2 / bars.length);
      final mult = isNear ? (1.0 + (1.0 - dist / (2 / bars.length)) * 0.10) : 1.0;

      final barHeight =
          (_waveMinBarHeight + bars[i] * (maxBarHeight - _waveMinBarHeight) * mult)
              .clamp(_waveMinBarHeight, maxBarHeight);

      _paintBar(canvas, barX, centerY, barHeight, isPlayed);
    }
  }

  void _paintBar(Canvas canvas, double x, double centerY, double height, bool isPlayed) {
    // Top segment
    canvas.drawRect(
      Rect.fromLTWH(x, centerY - (height * 0.68) / 2, _waveBarWidth, height * 0.68),
      Paint()
        ..color = isPlayed
            ? _wavePlayedColor
            : _waveUnplayedColor.withValues(alpha: 0.55),
    );

    // Bottom segment
    canvas.drawRect(
      Rect.fromLTWH(x, centerY + (height * 0.22) / 2 - height * 0.22,
          _waveBarWidth, height * 0.22),
      Paint()
        ..color = isPlayed
            ? _wavePlayedColor.withValues(alpha: 0.35)
            : _waveUnplayedColor.withValues(alpha: 0.18),
    );
  }

  void _drawTimeline(Canvas canvas, double waveformX, double centerY) {
    final playedWidth = (progress * totalWaveWidth).clamp(0.0, totalWaveWidth);

    // Played segment
    canvas.drawRect(
      Rect.fromLTWH(waveformX, centerY - 1, playedWidth, 2),
      Paint()..color = _wavePlayedColor,
    );

    // Unplayed segment
    canvas.drawRect(
      Rect.fromLTWH(waveformX + playedWidth, centerY - 1,
          totalWaveWidth - playedWidth, 2),
      Paint()..color = _waveUnplayedColor.withValues(alpha: 0.30),
    );

    // Playhead dot
    canvas.drawCircle(Offset(waveformX + playedWidth, centerY), 5,
        Paint()..color = _wavePlayedColor);
  }

  void _drawMarkers(Canvas canvas, double waveformX, double centerY) {
    if (duration == null || duration!.inSeconds == 0) return;

    final durationSeconds = duration!.inSeconds.toDouble();
    final markerY = centerY - waveformHeight / 2 + 12;

    for (final seconds in commentTimestamps) {
      final ratio = (seconds / durationSeconds).clamp(0.0, 1.0);
      final markerX = waveformX + (ratio * totalWaveWidth);

      if (markerX < -10 || markerX > screenWidth + 10) continue;

      canvas.drawCircle(Offset(markerX, markerY), 4, Paint()..color = _waveMarkerColor);
      canvas.drawCircle(
        Offset(markerX, markerY),
        4,
        Paint()
          ..color = Colors.black
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2,
      );
    }
  }

  void _drawPlayhead(Canvas canvas, double playheadX) {
    // Glow
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, waveformHeight),
      Paint()
        ..color = Colors.white.withValues(alpha: 0.7)
        ..strokeWidth = 1
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6),
    );

    // Line
    canvas.drawLine(
      Offset(playheadX, 0),
      Offset(playheadX, waveformHeight),
      Paint()
        ..color = Colors.white
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(_WaveformPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.isPlaying != isPlaying ||
      oldDelegate.bars != bars;
}
