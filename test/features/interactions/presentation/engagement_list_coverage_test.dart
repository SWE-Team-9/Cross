import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/interactions/data/dto/engagement_user_dto.dart';
import 'package:soundcloud_clone/features/interactions/data/dto/paginated_engagement_users_dto.dart';
import 'package:soundcloud_clone/features/interactions/domain/entities/engagement_user.dart';
import 'package:soundcloud_clone/features/interactions/domain/entities/paginated_engagement_users.dart';
import 'package:soundcloud_clone/features/interactions/domain/repositories/interactions_repository.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_track_likers_usecase.dart';
import 'package:soundcloud_clone/features/interactions/domain/usecases/get_track_reposters_usecase.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/pages/engagement_list_page.dart';

class MockInteractionsRepository extends Mock implements InteractionsRepository {}

class MockGetTrackLikersUseCase extends Mock implements GetTrackLikersUseCase {}

class MockGetTrackRepostersUseCase extends Mock
    implements GetTrackRepostersUseCase {}

class MockEngagementListCubit extends MockCubit<EngagementListState>
    implements EngagementListCubit {}

const paginatedUsers = PaginatedEngagementUsers(
  items: [
    EngagementUser(
      userId: 'u1',
      displayName: 'Ali',
      avatarUrl: null,
      interactedAt: null,
    ),
  ],
  page: 1,
  limit: 20,
  total: 1,
  totalPages: 1,
  hasNextPage: false,
  hasPreviousPage: false,
);

void main() {
  setUpAll(() {
    registerFallbackValue(EngagementListType.likers);
  });

  group('DTOs and usecases', () {
    test('EngagementUserDto maps nested user and entity fields', () {
      final dto = EngagementUserDto.fromJson({
        'user': {
          'id': 'u1',
          'display_name': 'Ali',
          'avatar_url': 'https://example.com/avatar.png',
        },
        'interacted_at': '2026-01-02T12:00:00.000Z',
      });

      final entity = dto.toEntity();

      expect(dto.userId, 'u1');
      expect(entity.displayName, 'Ali');
      expect(entity.avatarUrl, 'https://example.com/avatar.png');
      expect(entity.interactedAt, DateTime.parse('2026-01-02T12:00:00.000Z'));
    });

    test('PaginatedEngagementUsersDto maps pagination and entities', () {
      final dto = PaginatedEngagementUsersDto.fromJson({
        'items': [
          {
            'user': {
              'userId': 'u1',
              'displayName': 'Ali',
            },
          },
        ],
        'pagination': {
          'page': '2',
          'limit': '20',
          'total': 30,
          'totalPages': 2,
          'hasNextPage': false,
          'hasPreviousPage': true,
        },
      });

      final entity = dto.toEntity();

      expect(entity.page, 2);
      expect(entity.limit, 20);
      expect(entity.totalPages, 2);
      expect(entity.hasPreviousPage, isTrue);
      expect(entity.items.single.userId, 'u1');
    });

    test('usecases delegate to repository', () async {
      final repository = MockInteractionsRepository();
      final likersUseCase = GetTrackLikersUseCase(repository);
      final repostersUseCase = GetTrackRepostersUseCase(repository);

      when(() => repository.getTrackLikers('t1', page: 3, limit: 15))
          .thenAnswer((_) async => paginatedUsers);
      when(() => repository.getTrackReposters('t1', page: 2, limit: 10))
          .thenAnswer((_) async => paginatedUsers);

      final likers = await likersUseCase('t1', page: 3, limit: 15);
      final reposters = await repostersUseCase('t1', page: 2, limit: 10);

      expect(likers.items.single.displayName, 'Ali');
      expect(reposters.items.single.userId, 'u1');
    });
  });

  group('EngagementListState', () {
    test('copyWith and title work for both types', () {
      final state = EngagementListState.initial().copyWith(
        errorMessage: 'error',
        type: EngagementListType.reposters,
      );
      final cleared = state.copyWith(clearError: true);

      expect(state.title, 'Reposted by');
      expect(cleared.errorMessage, isNull);
      expect(EngagementListState.initial().title, 'Liked by');
    });
  });

  group('EngagementListCubit', () {
    late MockGetTrackLikersUseCase getTrackLikersUseCase;
    late MockGetTrackRepostersUseCase getTrackRepostersUseCase;

    setUp(() {
      getTrackLikersUseCase = MockGetTrackLikersUseCase();
      getTrackRepostersUseCase = MockGetTrackRepostersUseCase();
    });

    EngagementListCubit buildCubit() => EngagementListCubit(
          getTrackLikersUseCase: getTrackLikersUseCase,
          getTrackRepostersUseCase: getTrackRepostersUseCase,
        );

    blocTest<EngagementListCubit, EngagementListState>(
      'load emits loading then loaded likers',
      build: () {
        when(() => getTrackLikersUseCase('t1', page: 1))
            .thenAnswer((_) async => paginatedUsers);
        return buildCubit();
      },
      act: (cubit) => cubit.load(
        trackId: 't1',
        type: EngagementListType.likers,
      ),
      expect: () => [
        isA<EngagementListState>()
            .having((s) => s.isLoading, 'isLoading', isTrue)
            .having((s) => s.trackId, 'trackId', 't1'),
        isA<EngagementListState>()
            .having((s) => s.isLoading, 'isLoading', isFalse)
            .having((s) => s.items.length, 'items', 1)
            .having((s) => s.hasNextPage, 'hasNextPage', isFalse),
      ],
    );

    blocTest<EngagementListCubit, EngagementListState>(
      'loadMore appends results',
      build: () {
        when(() => getTrackLikersUseCase('t1', page: 2)).thenAnswer(
          (_) async => const PaginatedEngagementUsers(
            items: [
              EngagementUser(
                userId: 'u2',
                displayName: 'Salma',
                avatarUrl: null,
                interactedAt: null,
              ),
            ],
            page: 2,
            limit: 20,
            total: 2,
            totalPages: 2,
            hasNextPage: false,
            hasPreviousPage: true,
          ),
        );
        return buildCubit();
      },
      seed: () => const EngagementListState(
        isLoading: false,
        isLoadingMore: false,
        items: [
          EngagementUser(
            userId: 'u1',
            displayName: 'Ali',
            avatarUrl: null,
            interactedAt: null,
          ),
        ],
        errorMessage: null,
        page: 1,
        hasNextPage: true,
        type: EngagementListType.likers,
        trackId: 't1',
      ),
      act: (cubit) => cubit.loadMore(),
      expect: () => [
        isA<EngagementListState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isTrue),
        isA<EngagementListState>()
            .having((s) => s.isLoadingMore, 'isLoadingMore', isFalse)
            .having((s) => s.items.length, 'items length', 2)
            .having((s) => s.page, 'page', 2),
      ],
    );

    blocTest<EngagementListCubit, EngagementListState>(
      'load emits error state on failure',
      build: () {
        when(() => getTrackRepostersUseCase('t1', page: 1))
            .thenThrow(Exception('boom'));
        return buildCubit();
      },
      act: (cubit) => cubit.load(
        trackId: 't1',
        type: EngagementListType.reposters,
      ),
      expect: () => [
        isA<EngagementListState>()
            .having((s) => s.isLoading, 'isLoading', true),
        isA<EngagementListState>()
            .having((s) => s.isLoading, 'isLoading', false)
            .having((s) => s.errorMessage, 'errorMessage', contains('boom')),
      ],
    );
  });

  group('EngagementListPage', () {
    late MockEngagementListCubit cubit;

    setUp(() {
      cubit = MockEngagementListCubit();
      when(() => cubit.load(
            trackId: any(named: 'trackId'),
            type: any(named: 'type'),
          )).thenAnswer((_) async {});
      when(() => cubit.loadMore()).thenAnswer((_) async {});
    });

    Widget buildPage(EngagementListState state) {
      when(() => cubit.state).thenReturn(state);
      when(() => cubit.stream)
          .thenAnswer((_) => const Stream<EngagementListState>.empty());

      return MaterialApp(
        home: BlocProvider<EngagementListCubit>.value(
          value: cubit,
          child: const EngagementListPage(
            trackId: 'track-1',
            type: EngagementListType.likers,
          ),
        ),
      );
    }

    testWidgets('loads on init and shows loading spinner', (tester) async {
      await tester.pumpWidget(
        buildPage(EngagementListState.initial().copyWith(isLoading: true)),
      );

      verify(() => cubit.load(
            trackId: 'track-1',
            type: EngagementListType.likers,
          )).called(1);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows error state', (tester) async {
      await tester.pumpWidget(
        buildPage(
          EngagementListState.initial().copyWith(errorMessage: 'bad request'),
        ),
      );
      expect(find.text('bad request'), findsOneWidget);
    });

    testWidgets('shows empty state', (tester) async {
      await tester.pumpWidget(
        buildPage(
          EngagementListState.initial(),
        ),
      );
      await tester.pump();

      expect(find.text('No likes yet'), findsOneWidget);
    });

    testWidgets('renders users and triggers loadMore on scroll', (tester) async {
      final items = List.generate(
        25,
        (index) => EngagementUser(
          userId: 'u$index',
          displayName: 'User $index',
          avatarUrl: null,
          interactedAt: DateTime(2026, 1, index + 1),
        ),
      );

      await tester.binding.setSurfaceSize(const Size(400, 400));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        buildPage(
          EngagementListState.initial().copyWith(
            items: items,
            hasNextPage: true,
          ),
        ),
      );
      await tester.pump();

      expect(find.text('User 0'), findsOneWidget);
      expect(find.text('2026-01-01'), findsOneWidget);

      await tester.drag(find.byType(ListView), const Offset(0, -2000));
      await tester.pump();

      verify(() => cubit.loadMore()).called(greaterThan(0));
    });
  });
}
