import '../../domain/entities/ManagedTrack.dart';
import '../../domain/entities/TrackManagementForm.dart';
import '../../domain/entities/TrackManagementVisibility.dart';
import '../../domain/repositories/trackManagementRepository.dart';
import '../datasources/trackManagementRemoteDataSource.dart';

class TrackManagementRepositoryImpl implements TrackManagementRepository {
  const TrackManagementRepositoryImpl(this._trackManagementRemoteDataSource);

  final TrackManagementRemoteDataSource _trackManagementRemoteDataSource;

  @override
  Future<ManagedTrack> updateTrackMetadata({
    required String trackId,
    required TrackManagementForm form,
  }) {
    return _trackManagementRemoteDataSource.updateTrackMetadata(
      trackId: trackId,
      form: form,
    );
  }

  @override
  Future<ManagedTrack> updateTrackVisibility({
    required String trackId,
    required TrackManagementVisibility visibility,
  }) {
    return _trackManagementRemoteDataSource.updateTrackVisibility(
      trackId: trackId,
      visibility: visibility,
    );
  }

  @override
  Future<void> deleteTrack({
    required String trackId,
  }) {
    return _trackManagementRemoteDataSource.deleteTrack(
      trackId: trackId,
    );
  }
}
