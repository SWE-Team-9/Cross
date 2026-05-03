import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/errors/failure.dart';
import '../entities/search_entities.dart';
import '../repositories/search_repository.dart';

@lazySingleton
class SearchUseCase {
  final SearchRepository _repository;

  SearchUseCase(this._repository);

  Future<Either<Failure, SearchResultsEntity>> call(
    String query, {
    String? type,
    int page = 1,
    int limit = 20,
  }) {
    return _repository.search(
      query,
      type: type,
      page: page,
      limit: limit,
    );
  }
}