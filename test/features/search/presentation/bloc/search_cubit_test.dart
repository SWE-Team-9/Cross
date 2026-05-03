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

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late SearchCubit cubit;
  late MockSearchUseCase mockUseCase;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});
    registerFallbackValue(SearchQuery(''));
  });

  setUp(() {
    mockUseCase = MockSearchUseCase();
    cubit = SearchCubit(mockUseCase);
  });

  tearDown(() {
    cubit.close();
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
      build: () => cubit,
      setUp: () {
        when(() => mockUseCase(any(), page: any(named: 'page')))
            .thenAnswer((_) async => Right(SearchResultsEntity(
                  tracks: [],
                  users: [],
                  playlists: [],
                  meta: SearchMetaEntity(
                    currentPage: 1,
                    totalResults: 0,
                    totalPages: 1,
                  ),
                )));
      },
      act: (cubit) => cubit.submitSearch('test'),
      expect: () => [
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.idle)
            .having((s) => s.recentSearches, 'recentSearches', ['test']),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.loading)
            .having((s) => s.submittedQuery, 'submittedQuery', 'test'),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.success)
            .having((s) => s.currentPage, 'currentPage', 1),
      ],
      verify: (_) {
        verify(() => mockUseCase('test', page: 1)).called(1);
      },
    );

    blocTest<SearchCubit, SearchState>(
      'submitSearch emits failure on search failure',
      build: () => cubit,
      setUp: () {
        when(() => mockUseCase(any(), page: any(named: 'page')))
            .thenAnswer((_) async => Left(const ServerFailure()));
      },
      act: (cubit) => cubit.submitSearch('test'),
      expect: () => [
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.loading),
        isA<SearchState>()
            .having((s) => s.status, 'status', SearchStatus.failure)
            .having((s) => s.failure, 'failure', isA<ServerFailure>()),
      ],
    );

    test('onTabChanged updates active tab', () {
      cubit.onTabChanged(SearchTab.tracks);
      expect(cubit.state.activeTab, SearchTab.tracks);
    });

    test('loadNextPage does nothing if no submitted query', () async {
      await cubit.loadNextPage();
      expect(cubit.state.currentPage, 1);
    });

    test('loadNextPage does nothing if already loading more', () async {
      cubit.emit(const SearchState(
        submittedQuery: 'test',
        isLoadingMore: true,
        currentPage: 1,
        totalPages: 2,
      ));
      await cubit.loadNextPage();
      expect(cubit.state.currentPage, 1);
    });
  });
}
