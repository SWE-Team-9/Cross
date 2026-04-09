import 'package:equatable/equatable.dart';

/// Immutable domain model for a track's waveform.
///
/// Consumed by:
///   - [player_waveform.dart]  (Ali T3.5) — seekable waveform in full player
///   - Mini player widget      (Ali T3.6) — condensed waveform bar
///   - Upload success UI       (Abdallah T3.4) — waveform preview once ready
///
/// Never construct directly from JSON — use [WaveformParser] in the data layer.
class WaveformData extends Equatable {
  const WaveformData._({
    required this.rawPeaks,
    required this.normalizedPeaks,
  });

  final List<double> rawPeaks;
  final List<double> normalizedPeaks;

  // ─── Factories ─────────────────────────────────────────────────────────────

  factory WaveformData.fromRaw(List<dynamic> raw) {
    if (raw.isEmpty) return WaveformData.empty();

    final peaks = raw.map((e) => (e as num).toDouble()).toList(growable: false);

    return WaveformData._(
      rawPeaks: peaks,
      normalizedPeaks: _normalize(peaks),
    );
  }

  /// Returns an empty waveform — use when track is PROCESSING or data is null.
  /// Declared as a const constructor so it can be used as a default field value.
  const WaveformData.empty()
      : rawPeaks = const [],
        normalizedPeaks = const [];

  // ─── State helpers ─────────────────────────────────────────────────────────

  bool get isEmpty => normalizedPeaks.isEmpty;
  bool get isNotEmpty => normalizedPeaks.isNotEmpty;

  // ─── Rendering helpers ─────────────────────────────────────────────────────

  /// Returns [targetBarCount] resampled values for widget rendering.
  ///   full player  → resample(200)
  ///   mini player  → resample(60)
  ///   upload UI    → resample(80)
  List<double> resample(int targetBarCount) {
    if (isEmpty) return List.filled(targetBarCount, 0.0);
    if (normalizedPeaks.length == targetBarCount) return normalizedPeaks;

    final result = <double>[];
    final ratio = normalizedPeaks.length / targetBarCount;

    for (int i = 0; i < targetBarCount; i++) {
      final start = (i * ratio).floor();
      final end = ((i + 1) * ratio).ceil().clamp(0, normalizedPeaks.length);
      final slice = normalizedPeaks.sublist(start, end);
      result.add(slice.reduce((a, b) => a + b) / slice.length);
    }

    return result;
  }

  /// Returns the normalized peak amplitude at playback [progress] (0.0–1.0).
  double peakAt(double progress) {
    if (isEmpty) return 0.0;
    final index = (progress * (normalizedPeaks.length - 1))
        .round()
        .clamp(0, normalizedPeaks.length - 1);
    return normalizedPeaks[index];
  }

  // ─── Private ───────────────────────────────────────────────────────────────

  static List<double> _normalize(List<double> peaks) {
    if (peaks.isEmpty) return const [];

    final maxVal = peaks.reduce((a, b) => a > b ? a : b);
    final minVal = peaks.reduce((a, b) => a < b ? a : b);
    final range = maxVal - minVal;

    if (range == 0) return List.filled(peaks.length, 0.5);

    return peaks.map((p) => (p - minVal) / range).toList(growable: false);
  }

  @override
  List<Object?> get props => [rawPeaks, normalizedPeaks];
}
