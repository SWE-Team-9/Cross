// playback/domain/usecases/get_track_detail_use_case.dart

import '/core/errors/failure.dart';
import '../entities/track_details.dart';
import '../repositories/i_track_detail_repository.dart';

/// Fetches full track detail for a public track by its UUID.
///
/// Used by the deep link bridge when opening soundclone://track/{trackId}.
class GetTrackDetailUseCase {
  const GetTrackDetailUseCase(this._repository);

  final ITrackDetailRepository _repository;

  Future<({TrackDetail? detail, Failure? failure})> call(
    String trackId,
  ) {
    return _repository.getByTrackId(trackId);
  }
}