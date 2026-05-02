// lib/features/discovery/domain/usecases/get_trending_usecase.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/trending_track.dart';
import '../repositories/trending_repository.dart';

class GetTrendingUseCase {
  final TrendingRepository _repository;

  const GetTrendingUseCase(this._repository);

  Future<Either<Failure, List<TrendingTrack>>> call() {
    return _repository.getTrending();
  }
}