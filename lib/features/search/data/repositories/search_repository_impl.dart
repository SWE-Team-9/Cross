// lib/features/search/data/repositories/search_repository_impl.dart

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/errors/failure.dart';
import '../../domain/entities/search_entities.dart';
import '../../domain/repositories/search_repository.dart';
import '../datasources/search_remote_data_source.dart';

@LazySingleton(as: SearchRepository)
class SearchRepositoryImpl implements SearchRepository {
  final SearchRemoteDataSource _remote;

  SearchRepositoryImpl(this._remote);

  // Simple LRU-style in-memory cache keyed by "query:page"
  // Lives as long as the singleton — cleared on logout by calling clearCache().
  final _cache = <String, SearchResultsEntity>{};
  static const _maxCacheSize = 30;

  @override
  Future<Either<Failure, SearchResultsEntity>> search(
    String query, {
    int page = 1,
  }) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const Right(SearchResultsEntity(
        tracks: [],
        users: [],
        playlists: [],
        meta: SearchMetaEntity(
          currentPage: 1,
          totalResults: 0,
          totalPages: 0,
        ),
      ));
    }

    final cacheKey = '$trimmed:$page';

    // Cache hit
    final cached = _cache[cacheKey];
    if (cached != null) return Right(cached);

    try {
      final model = await _remote.search(trimmed, page: page);
      final entity = model.toEntity();

      // Evict oldest entry if over limit
      if (_cache.length >= _maxCacheSize) {
        _cache.remove(_cache.keys.first);
      }
      _cache[cacheKey] = entity;

      return Right(entity);
    } on Failure catch (f) {
      return Left(f);
    } catch (_) {
      return const Left(ServerFailure());
    }
  }

  @override
  void clearCache() => _cache.clear();
}
