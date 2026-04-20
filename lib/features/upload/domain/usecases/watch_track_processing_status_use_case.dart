import 'package:injectable/injectable.dart';

import '../entities/track_processing_status.dart';
import '../entities/track_status.dart';
import '../repositories/i_track_status_repository.dart';

/// Polls GET /api/v1/tracks/{trackId}/status until a terminal state
/// (FINISHED or FAILED) is reached, then closes the stream.
///
/// Backoff schedule:
///   attempts 1–3  →  3 seconds
///   attempts 4–6  →  5 seconds
///   attempts 7+   →  10 seconds (cap)
///   max attempts  →  20 (then emits FAILED and closes)
@injectable
class WatchTrackProcessingStatusUseCase {
  const WatchTrackProcessingStatusUseCase(this._repository);

  final ITrackStatusRepository _repository;

  static const int _MAX_ATTEMPTS = 20;

  Stream<TrackProcessingStatus> call(String trackId) async* {
    int attempt = 0;

    while (attempt < _MAX_ATTEMPTS) {
      attempt++;

      final result = await _repository.getTrackStatus(trackId);

      final status = result.failure != null
          ? TrackProcessingStatus(
              trackId: trackId,
              status: TrackStatus.FAILED,
            )
          : result.status!;

      yield status;

      if (status.isTerminal) return;

      await Future.delayed(_backoffFor(attempt));
    }

    yield TrackProcessingStatus(
      trackId: trackId,
      status: TrackStatus.FAILED,
    );
  }

  Duration _backoffFor(int attempt) {
    if (attempt <= 3) return const Duration(seconds: 3);
    if (attempt <= 6) return const Duration(seconds: 5);
    return const Duration(seconds: 10);
  }
}
