import '/core/errors/failure.dart';
import '../entities/track_details.dart';

abstract interface class ITrackDetailRepository {
  Future<({TrackDetail? detail, Failure? failure})> getByTrackId(
    String trackId,
  );

  Future<({TrackDetail? detail, Failure? failure})> getBySecretToken(
    String secretToken,
  );

  // ✅ الجديد
  Future<({TrackDetail? detail, Failure? failure})> getBySlug(
    String handle,
    String slug,
  );
}