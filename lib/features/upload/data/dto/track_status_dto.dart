import '../../domain/entities/track_processing_status.dart';
import '../../domain/entities/track_status.dart';

/// Maps GET /api/v1/tracks/{trackId}/status response:
/// { "trackId": "trk_12345", "status": "PROCESSING" }
class TrackStatusDto {
  const TrackStatusDto({
    required this.trackId,
    required this.status,
  });

  factory TrackStatusDto.fromJson(Map<String, dynamic> json) {
    return TrackStatusDto(
      trackId: (json['trackId'] ?? '').toString(),
      status: TrackStatus.fromString(json['status']?.toString()),
    );
  }

  final String trackId;
  final TrackStatus status;

  TrackProcessingStatus toEntity() {
    return TrackProcessingStatus(
      trackId: trackId,
      status: status,
    );
  }
}
