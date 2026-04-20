import '../../domain/entities/waveform_data.dart';

/// Extracts [WaveformData] from any track API response payload.
///
/// Works with all endpoints that return waveformData:
///   GET /api/v1/tracks/{trackId}          → full track detail
///   GET /api/v1/users/{userId}/tracks     → artist track list items
///   GET /api/v1/tracks/secret/{token}     → private track by token
///
/// Always returns [WaveformData.empty()] rather than throwing —
/// handles null (track still PROCESSING) and malformed data gracefully.
class WaveformParser {
  const WaveformParser._();

  static WaveformData fromTrackJson(Map<String, dynamic> json) {
    final raw = json['waveformData'];

    if (raw == null || raw is! List || raw.isEmpty) {
      return const WaveformData.empty();
    }

    try {
      return WaveformData.fromRaw(raw);
    } catch (_) {
      return const WaveformData.empty();
    }
  }
}
