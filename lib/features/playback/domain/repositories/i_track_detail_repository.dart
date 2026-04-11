// playback/domain/repositories/i_track_detail_repository.dart

import '/core/errors/failure.dart';
import '../entities/track_details.dart';

/// Contract for fetching full track detail including stream URL.
///
/// Two entry points:
/// - [getByTrackId] — for public tracks via soundclone://track/{trackId}
/// - [getBySecretToken] — for private tracks via soundclone://track/secret/{token}
///
/// Both return a named record so callers never deal with exceptions.
abstract interface class ITrackDetailRepository {
  /// Fetches full track detail for a public track.
  /// Calls GET /api/v1/tracks/{trackId} + GET /api/v1/player/tracks/{trackId}/source
  Future<({TrackDetail? detail, Failure? failure})> getByTrackId(
    String trackId,
  );

  /// Fetches full track detail for a private track via secret share token.
  /// Calls GET /api/v1/tracks/secret/{token} + GET /api/v1/player/tracks/{trackId}/source
  Future<({TrackDetail? detail, Failure? failure})> getBySecretToken(
    String secretToken,
  );
}