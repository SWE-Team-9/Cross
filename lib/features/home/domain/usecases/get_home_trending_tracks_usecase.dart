import 'package:soundcloud_clone/core/models/track.dart';

import '../repositories/home_repository.dart';

class GetHomeTrendingTracksUseCase {
  const GetHomeTrendingTracksUseCase(this._repository);

  final HomeRepository _repository;

  Future<List<Track>> call({
    required String genre,
    int limit = 5,
  }) {
    return _repository.getTrendingTracks(
      genre: genre,
      limit: limit,
    );
  }
}
