import 'package:dio/dio.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/track_processing_status.dart';
import '../../domain/repositories/i_track_status_repository.dart';
import '../datasources/track_status_remote_data_source.dart';

@LazySingleton(as: ITrackStatusRepository)
class TrackStatusRepositoryImpl implements ITrackStatusRepository {
  const TrackStatusRepositoryImpl(this._remoteDataSource);

  final TrackStatusRemoteDataSource _remoteDataSource;

  @override
  Future<({TrackProcessingStatus? status, Failure? failure})> getTrackStatus(
    String trackId,
  ) async {
    try {
      final dto = await _remoteDataSource.getTrackStatus(trackId);
      return (status: dto.toEntity(), failure: null);
    } on DioException catch (e) {
      return (
        status: null,
        failure: ServerFailure(e.message ?? 'Failed to fetch track status'),
      );
    } catch (e) {
      return (status: null, failure: ServerFailure(e.toString()));
    }
  }
}
