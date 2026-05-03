import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/search/domain/entities/search_entities.dart';
import 'package:soundcloud_clone/features/search/domain/usecases/search_usecase.dart';
import 'package:soundcloud_clone/features/search/presentation/bloc/search_cubit.dart';

class MockSearchUseCase extends Mock implements SearchUseCase {}

void main() {
  late SearchCubit cubit;
  late MockSearchUseCase mockUseCase;

  const emptyResults = SearchResultsEntity(
    tracks: [],
    users: [],
    playlists: [],
    meta: SearchMetaEntity(
      currentPage: 1,
      totalResults: 0,
      totalPages: 1,
    ),
  );

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
    mockUseCase = MockSearchUseCase();
    cubit = SearchCubit(mockUseCase);
  });

  tearDown(() async {
    await cubit.close();
  });

  group('SearchCubit', () {
    test('initial state is correct', () {
      expect(cubit.state, const SearchState());
      expect(cubit.state.status, SearchStatus.idle);
      expect(cubit.state.activeTab, SearchTab.all);
    });

    test('onQueryChanged with empty query keeps idle state', () {
      cubit.onQueryChanged('');

      expect(cubit.state.typingQuery, '');
      expect(cubit.state.status, SearchStatus.idle);
      expect(cubit.state.submittedQuery, '');
    });

    blocTest<SearchCubit, SearchState>(
      'submitSearch emits recents update, loading then success on successful search',
      build: () {
        when(
          () => mockUseCase(
            any(),
            type: any(named: 'type'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Right(emptyResults));

        return SearchCubit(mockUseCase);
      },
      skip: 1,
      act: (cubit) => cubit.submitSearch('test'),
      expect: () => [
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.idle)
            .having((s) => s.recentSearches, 'recentSearches', ['test']),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.loading)
            .having((s) => s.submittedQuery, 'submittedQuery', 'test')
            .having((s) => s.typingQuery, 'typingQuery', 'test'),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.success)
            .having((s) => s.currentPage, 'currentPage', 1)
            .having((s) => s.totalPages, 'totalPages', 1),
      ],
      verify: (_) {
        verify(
          () => mockUseCase(
            'test',
            type: 'all',
            page: 1,
            limit: 10,
          ),
        ).called(1);
      },
    );

    blocTest<SearchCubit, SearchState>(
      'submitSearch emits failure on search failure',
      build: () {
        when(
          () => mockUseCase(
            any(),
            type: any(named: 'type'),
            page: any(named: 'page'),
            limit: any(named: 'limit'),
          ),
        ).thenAnswer((_) async => const Left(ServerFailure()));

        return SearchCubit(mockUseCase);
      },
      skip: 1,
      act: (cubit) => cubit.submitSearch('test'),
      expect: () => [
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.idle)
            .having((s) => s.recentSearches, 'recentSearches', ['test']),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.loading),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.failure)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
      verify: (_) {
        verify(
          () => mockUseCase(
            'test',
            type: 'all',
            page: 1,
            limit: 10,
          ),
        ).called(1);
      },
    );

    test('onTabChanged updates active tab', () async {
      await cubit.onTabChanged(SearchTab.tracks);

      expect(cubit.state.activeTab, SearchTab.tracks);
    });

    test('loadNextPage does nothing if no submitted query', () async {
      await cubit.loadNextPage();

      expect(cubit.state.currentPage, 1);
    });

    test('loadNextPage does nothing if already loading more', () async {
      cubit.emit(
        const SearchState(
          submittedQuery: 'test',
          isLoadingMore: true,
          currentPage: 1,
          totalPages: 2,
        ),
      );

      await cubit.loadNextPage();

      expect(cubit.state.currentPage, 1);
    });
  });
}
