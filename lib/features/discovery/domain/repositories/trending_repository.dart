// lib/features/discovery/domain/repositories/trending_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/trending_track.dart';

abstract class TrendingRepository {
  Future<Either<Failure, List<TrendingTrack>>> getTrending();
}