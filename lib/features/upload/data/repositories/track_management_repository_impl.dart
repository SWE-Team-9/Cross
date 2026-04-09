import '../../domain/entities/managed_track.dart';
import '../../domain/entities/track_management_form.dart';
import '../../domain/entities/track_management_visibility.dart';
import '../../domain/repositories/track_management_repository.dart';
import '../datasources/track_management_remote_data_source.dart';

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
