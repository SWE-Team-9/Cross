// lib/features/search/domain/usecases/genre_usecase.dart
// ─────────────────────────────────────────────────────────────────────────────
// Use-case interfaces for the genre page.
// Implement GenreUseCase in your data layer by calling your existing
// SoundCloud-compatible API endpoints.
// ─────────────────────────────────────────────────────────────────────────────

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../entities/genre_entities.dart';
import '../repositories/genre_repository.dart';

// ── Fetch genre page data ─────────────────────────────────────────────────────

@injectable
class GenreUseCase {
  final GenreRepository _repo;
  GenreUseCase(this._repo);

  Future<Either<Failure, GenrePageData>> call(String genreQuery) =>
      _repo.fetchGenrePage(genreQuery);
}

// ── Follow / unfollow a user ──────────────────────────────────────────────────

@injectable
class FollowUserUseCase {
  final GenreRepository _repo;
  FollowUserUseCase(this._repo);

  Future<Either<Failure, void>> call({
    required String userId,
    required bool follow,
  }) =>
      _repo.followUser(userId: userId, follow: follow);
}
