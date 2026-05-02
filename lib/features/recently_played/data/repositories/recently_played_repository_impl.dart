import '../../../../core/models/track.dart';
import '../datasources/recently_played_remote_datasource.dart';

class RecentlyPlayedRepositoryImpl {
  const RecentlyPlayedRepositoryImpl(this._remoteDataSource);

  final RecentlyPlayedRemoteDataSource _remoteDataSource;

  Future<List<Track>> getListeningHistory({int page = 1, int limit = 20}) {
    return _remoteDataSource.getListeningHistory(page: page, limit: limit);
  }

  Future<void> recordTrackPlay(String trackId) {
    return _remoteDataSource.recordTrackPlay(trackId);
  }
}
