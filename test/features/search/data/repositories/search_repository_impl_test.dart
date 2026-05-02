import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/search/data/datasources/search_remote_data_source.dart';
import 'package:soundcloud_clone/features/search/data/dto/search_models.dart';
import 'package:soundcloud_clone/features/search/data/repositories/search_repository_impl.dart';
import 'package:soundcloud_clone/features/search/domain/entities/search_entities.dart';

class MockSearchRemoteDataSource extends Mock
    implements SearchRemoteDataSource {}

void main() {
  late SearchRepositoryImpl repository;
  late MockSearchRemoteDataSource mockRemote;

  setUp(() {
    mockRemote = MockSearchRemoteDataSource();
    repository = SearchRepositoryImpl(mockRemote);
  });

  group('SearchRepositoryImpl', () {
    const tQuery = 'test';
    const tPage = 1;
    final tSearchResults = SearchResultsEntity(
      tracks: [],
      users: [],
      playlists: [],
      meta: SearchMetaEntity(
        currentPage: 1,
        totalResults: 0,
        totalPages: 0,
      ),
    );
    final tSearchModel = SearchResponseModel(
      tracks: [],
      users: [],
      playlists: [],
      meta: SearchMetaModel(
        currentPage: 1,
        totalResults: 0,
        totalPages: 0,
      ),
    );

    test('returns empty results for empty query', () async {
      final result = await repository.search('', page: tPage);

      expect(result.isRight(), true);
      final entity = result.getOrElse(() => throw Exception());
      expect(entity.isEmpty, true);
      expect(entity.meta.currentPage, 1);
      verifyZeroInteractions(mockRemote);
    });

    test('returns cached result on cache hit', () async {
      // First call to populate cache
      when(() => mockRemote.search(tQuery, page: tPage))
          .thenAnswer((_) async => tSearchModel);

      await repository.search(tQuery, page: tPage);

      // Second call should use cache
      final result = await repository.search(tQuery, page: tPage);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw Exception()), equals(tSearchResults));
      verify(() => mockRemote.search(tQuery, page: tPage)).called(1);
    });

    test('returns remote result and caches it', () async {
      when(() => mockRemote.search(tQuery, page: tPage))
          .thenAnswer((_) async => tSearchModel);

      final result = await repository.search(tQuery, page: tPage);

      expect(result.isRight(), true);
      expect(result.getOrElse(() => throw Exception()), equals(tSearchResults));
      verify(() => mockRemote.search(tQuery, page: tPage)).called(1);
    });

    test('returns Left with Failure on remote failure', () async {
      when(() => mockRemote.search(tQuery, page: tPage))
          .thenThrow(const ServerFailure());

      final result = await repository.search(tQuery, page: tPage);

      expect(result.isLeft(), true);
      expect(result.swap().getOrElse(() => throw Exception()),
          isA<ServerFailure>());
      verify(() => mockRemote.search(tQuery, page: tPage)).called(1);
    });

    test('returns Left with ServerFailure on unexpected error', () async {
      when(() => mockRemote.search(tQuery, page: tPage))
          .thenThrow(Exception('unexpected'));

      final result = await repository.search(tQuery, page: tPage);

      expect(result.isLeft(), true);
      expect(result.swap().getOrElse(() => throw Exception()),
          isA<ServerFailure>());
      verify(() => mockRemote.search(tQuery, page: tPage)).called(1);
    });

    test('clears cache when clearCache is called', () async {
      when(() => mockRemote.search(tQuery, page: tPage))
          .thenAnswer((_) async => tSearchModel);

      await repository.search(tQuery, page: tPage);
      repository.clearCache();

      // After clear, should call remote again
      final result = await repository.search(tQuery, page: tPage);

      expect(result.isRight(), true);
      verify(() => mockRemote.search(tQuery, page: tPage)).called(2);
    });
  });
}
