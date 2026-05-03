import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../../domain/entities/genre_entities.dart';
import '../../domain/repositories/genre_repository.dart';
import '../datasources/genre_remote_datasource.dart';

@LazySingleton(as: GenreRepository)
class GenreRepositoryImpl implements GenreRepository {
  final GenreRemoteDatasource _remote;

  GenreRepositoryImpl(this._remote);

  @override
  Future<Either<Failure, GenrePageData>> fetchGenrePage(
    String genreQuery,
  ) async {
    try {
      final data = await _remote.fetchGenrePage(genreQuery);
      return Right(data);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> followUser({
    required String userId,
    required bool follow,
  }) async {
    try {
      await _remote.followUser(userId: userId, follow: follow);
      return const Right(null);
    } on Failure catch (failure) {
      return Left(failure);
    } catch (error) {
      return Left(ServerFailure(error.toString()));
    }
  }
}
