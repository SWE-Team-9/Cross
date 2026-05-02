// lib/features/discovery/data/repositories/trending_repository_impl.dart

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
  Future<Either<Failure, List<TrendingTrack>>> getTrending() async {
    try {
      final tracks = await _remoteDataSource.getTrending();
      return Right(tracks);
    } on ServerFailure catch (e) {
      return Left(e);
    } on NetworkFailure catch (e) {
      return Left(e);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }
}
