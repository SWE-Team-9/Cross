// lib/features/search/domain/usecases/search_usecase.dart

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
    int page = 1,
  }) =>
      _repository.search(query, page: page);
}
