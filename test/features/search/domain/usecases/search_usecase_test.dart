import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/search/domain/entities/search_entities.dart';
import 'package:soundcloud_clone/features/search/domain/repositories/search_repository.dart';
import 'package:soundcloud_clone/features/search/domain/usecases/search_usecase.dart';

class MockSearchRepository extends Mock implements SearchRepository {}

void main() {
  late SearchUseCase useCase;
  late MockSearchRepository mockRepository;

  setUp(() {
    mockRepository = MockSearchRepository();
    useCase = SearchUseCase(mockRepository);
  });

  group('SearchUseCase', () {
    const tQuery = 'indie';
    const tPage = 2;
    const tSearchMeta = SearchMetaEntity(
      currentPage: tPage,
      totalResults: 0,
      totalPages: 0,
    );
    const tSearchResults = SearchResultsEntity(
      tracks: [],
      users: [],
      playlists: [],
      meta: tSearchMeta,
    );

    test('returns search results when repository returns Right', () async {
      when(() => mockRepository.search(tQuery, page: tPage))
          .thenAnswer((_) async => const Right(tSearchResults));

      final result = await useCase(tQuery, page: tPage);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw Exception()), equals(tSearchResults));
      verify(() => mockRepository.search(tQuery, page: tPage)).called(1);
      verifyNoMoreInteractions(mockRepository);
    });

    test('rethrows failures from repository', () async {
      when(() => mockRepository.search(tQuery, page: tPage)).thenThrow(
        const ServerFailure('Server failure'),
      );

      expect(
        () async => await useCase(tQuery, page: tPage),
        throwsA(isA<ServerFailure>()),
      );
      verify(() => mockRepository.search(tQuery, page: tPage)).called(1);
    });
  });
}
