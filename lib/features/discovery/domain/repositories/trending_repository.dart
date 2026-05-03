import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/trending_track.dart';

abstract class TrendingRepository {
  Future<Either<Failure, List<TrendingTrack>>> getTrending({
    int limit = 20,
    int windowDays = 7,
  });
}
