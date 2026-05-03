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
      final trackDto = await _dataSource.fetchByTrackId(trackId);

      if (trackDto.trackId.isEmpty) {
        return (detail: null, failure: NotFoundFailure('Track not found.'));
      }

      final sourceDto = await _dataSource.fetchStreamSource(trackDto.trackId);

      if (sourceDto.isBlocked) {
        return (
          detail: null,
          failure:
              ForbiddenFailure('This track is not available for playback.'),
        );
      }

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

  @override
  Future<({TrackDetail? detail, Failure? failure})> getBySecretToken(
    String secretToken,
  ) async {
    try {
      final trackDto = await _dataSource.fetchBySecretToken(secretToken);

      if (trackDto.trackId.isEmpty) {
        return (
          detail: null,
          failure: NotFoundFailure('This link is no longer valid.'),
        );
      }

      final sourceDto = await _dataSource.fetchStreamSource(trackDto.trackId);

      if (sourceDto.isBlocked) {
        return (
          detail: null,
          failure:
              ForbiddenFailure('This track is not available for playback.'),
        );
      }

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

  // ✅ الجديد
  @override
  Future<({TrackDetail? detail, Failure? failure})> getBySlug(
    String handle,
    String slug,
  ) async {
    try {
      final trackDto = await _dataSource.fetchBySlug(handle, slug);

      if (trackDto.trackId.isEmpty) {
        return (detail: null, failure: NotFoundFailure('Track not found.'));
      }

      final sourceDto = await _dataSource.fetchStreamSource(trackDto.trackId);

      if (sourceDto.isBlocked) {
        return (
          detail: null,
          failure:
              ForbiddenFailure('This track is not available for playback.'),
        );
      }

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
