// lib/features/search/domain/repositories/search_repository.dart

import 'package:dartz/dartz.dart';
import '../../../../core/errors/failure.dart';
import '../entities/search_entities.dart';

abstract class SearchRepository {
  Future<Either<Failure, SearchResultsEntity>> search(
    String query, {
    int page = 1,
  });

  /// Clear the in-memory cache (call on logout or memory pressure).
  void clearCache();
}
