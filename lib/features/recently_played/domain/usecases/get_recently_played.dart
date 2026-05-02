import '../../../../core/models/track.dart';
import '../../data/repositories/recently_played_repository_impl.dart';

class GetRecentlyPlayed {
  const GetRecentlyPlayed(this._repository);

  final RecentlyPlayedRepositoryImpl _repository;

  Future<List<Track>> call({int page = 1, int limit = 20}) {
    return _repository.getListeningHistory(page: page, limit: limit);
  }
}

class RecordRecentlyPlayed {
  const RecordRecentlyPlayed(this._repository);

  final RecentlyPlayedRepositoryImpl _repository;

  Future<void> call(String trackId) {
    return _repository.recordTrackPlay(trackId);
  }
}
