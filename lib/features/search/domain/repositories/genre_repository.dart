// lib/features/search/domain/repositories/genre_repository.dart

import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/genre_entities.dart';

abstract class GenreRepository {
  /// Fetches all sections needed for the genre page.
  /// Data is derived from existing track/discovery/social endpoints —
  /// no dedicated genre endpoint is called.
  Future<Either<Failure, GenrePageData>> fetchGenrePage(String genreQuery);

  /// Follow or unfollow a user.
  Future<Either<Failure, void>> followUser({
    required String userId,
    required bool   follow,
  });
}