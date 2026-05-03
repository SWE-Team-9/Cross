import '/core/errors/failure.dart';
import '../entities/track_details.dart';
import '../repositories/i_track_detail_repository.dart';

class GetTrackDetailUseCase {
  const GetTrackDetailUseCase(this._repository);

  final ITrackDetailRepository _repository;

  Future<({TrackDetail? detail, Failure? failure})> call(
    String trackId,
  ) {
    return _repository.getByTrackId(trackId);
  }

  // ✅ الجديد
  Future<({TrackDetail? detail, Failure? failure})> callBySlug(
    String handle,
    String slug,
  ) {
    return _repository.getBySlug(handle, slug);
  }
}