import 'package:dartz/dartz.dart';

import '../../../../core/errors/failure.dart';
import '../entities/search_entities.dart';

abstract class SearchRepository {
  Future<Either<Failure, SearchResultsEntity>> search(
    String query, {
    String? type,
    int page = 1,
    int limit = 20,
  });

  void clearCache();
}