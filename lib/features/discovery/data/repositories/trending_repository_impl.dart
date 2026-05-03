import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/trending_track.dart';
import '../../domain/repositories/trending_repository.dart';
import '../datasources/discovery_remote_data_source.dart';

class TrendingRepositoryImpl implements TrendingRepository {
  final DiscoveryRemoteDataSource _remoteDataSource;

  const TrendingRepositoryImpl({
    required DiscoveryRemoteDataSource remoteDataSource,
  }) : _remoteDataSource = remoteDataSource;

  @override
  Future<Either<Failure, List<TrendingTrack>>> getTrending({
    int limit = 20,
    int windowDays = 7,
  }) async {
    try {
      final tracks = await _remoteDataSource.getTrending(
        limit: limit,
        windowDays: windowDays,
      );

      return Right(tracks);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
