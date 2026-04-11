// playback/domain/usecases/get_track_by_secret_use_case.dart

import '/core/errors/failure.dart';
import '../entities/track_details.dart';
import '../repositories/i_track_detail_repository.dart';

/// Fetches full track detail for a private track by its secret share token.
///
/// Used by the deep link bridge when opening
/// soundclone://track/secret/{secretToken}.
class GetTrackBySecretUseCase {
  const GetTrackBySecretUseCase(this._repository);

  final ITrackDetailRepository _repository;

  Future<({TrackDetail? detail, Failure? failure})> call(
    String secretToken,
  ) {
    return _repository.getBySecretToken(secretToken);
  }
}