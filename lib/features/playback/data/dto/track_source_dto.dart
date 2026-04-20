// playback/data/dto/track_source_dto.dart

/// Maps raw JSON from:
///   GET /api/v1/player/tracks/{trackId}/source
///
/// Response shape:
/// {
///   "trackId": "uuid",
///   "streamUrl": "https://cdn.example.com/audio/trk_123.mp3",
///   "accessState": "PLAYABLE",
///   "expiresAt": "2026-03-07T18:30:00Z"
/// }
class TrackSourceDto {
  const TrackSourceDto({
    required this.trackId,
    required this.streamUrl,
    required this.accessState,
  });

  final String trackId;
  final String streamUrl;

  /// PLAYABLE | PREVIEW | BLOCKED
  final String accessState;

  factory TrackSourceDto.fromJson(Map<String, dynamic> json) {
    return TrackSourceDto(
      trackId: (json['trackId'] as String?) ?? '',
      streamUrl: (json['streamUrl'] as String?) ?? '',
      accessState: (json['accessState'] as String?) ?? 'BLOCKED',
    );
  }

  bool get isPlayable => accessState == 'PLAYABLE';
  bool get isPreview => accessState == 'PREVIEW';
  bool get isBlocked => accessState == 'BLOCKED';
}
