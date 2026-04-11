// playback/data/repositories/track_detail_repository_impl.dart

// Third-party

// Project
import '../../../../core/errors/failure.dart';
import '../../domain/entities/track_details.dart';
import '../../domain/repositories/i_track_detail_repository.dart';
import '../datasources/track_detail_remote_data_source.dart';

class TrackDetailRepositoryImpl implements ITrackDetailRepository {
  const TrackDetailRepositoryImpl(this._dataSource);

  final TrackDetailRemoteDataSource _dataSource;

  @override
  Future<({TrackDetail? detail, Failure? failure})> getByTrackId(
    String trackId,
  ) async {
    try {
      // Step 1 — fetch track detail
      final trackDto = await _dataSource.fetchByTrackId(trackId);

      if (trackDto.trackId.isEmpty) {
        return (
          detail: null,
          failure: NotFoundFailure('Track not found.'),
        );
      }

      // Step 2 — fetch stream URL
      final sourceDto = await _dataSource.fetchStreamSource(trackDto.trackId);

      if (!sourceDto.isPlayable) {
        return (
          detail: null,
          failure:
              ForbiddenFailure('This track is not available for playback.'),
        );
      }

      // Step 3 — combine into entity
      return (
        detail: trackDto.toEntity(streamUrl: sourceDto.streamUrl),
        failure: null,
      );
    } on Failure catch (f) {
      // DioClient already mapped DioException → Failure via ErrorMapper.
      // We just catch and forward it here.
      return (detail: null, failure: f);
    } catch (_) {
      return (
        detail: null,
        failure: ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }

  @override
  Future<({TrackDetail? detail, Failure? failure})> getBySecretToken(
    String secretToken,
  ) async {
    try {
      // Step 1 — fetch private track detail via token
      final trackDto = await _dataSource.fetchBySecretToken(secretToken);

      if (trackDto.trackId.isEmpty) {
        return (
          detail: null,
          failure: NotFoundFailure('This link is no longer valid.'),
        );
      }

      // Step 2 — fetch stream URL using resolved trackId
      final sourceDto = await _dataSource.fetchStreamSource(trackDto.trackId);

      if (!sourceDto.isPlayable) {
        return (
          detail: null,
          failure:
              ForbiddenFailure('This track is not available for playback.'),
        );
      }

      // Step 3 — combine into entity
      return (
        detail: trackDto.toEntity(streamUrl: sourceDto.streamUrl),
        failure: null,
      );
    } on Failure catch (f) {
      return (detail: null, failure: f);
    } catch (_) {
      return (
        detail: null,
        failure: ServerFailure('Something went wrong. Please try again.'),
      );
    }
  }
}
