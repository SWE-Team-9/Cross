import '../../../../core/errors/failure.dart';
import '../entities/track_processing_status.dart';

abstract class ITrackStatusRepository {
  /// Calls GET /api/v1/tracks/{trackId}/status.
  /// Returns a named record with either [status] or [failure] set.
  Future<({TrackProcessingStatus? status, Failure? failure})> getTrackStatus(
    String trackId,
  );
}
