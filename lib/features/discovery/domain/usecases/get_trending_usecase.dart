import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/trending_track.dart';
import '../repositories/trending_repository.dart';

class GetTrendingUseCase {
  final TrendingRepository _repository;

  const GetTrendingUseCase(this._repository);

  Future<Either<Failure, List<TrendingTrack>>> call({
    int limit = 20,
    int windowDays = 7,
  }) {
    return _repository.getTrending(
      limit: limit,
      windowDays: windowDays,
    );
  }
}
