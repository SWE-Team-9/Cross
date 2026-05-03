import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/search/domain/entities/genre_entities.dart';
import 'package:soundcloud_clone/features/search/domain/repositories/genre_repository.dart';
import 'package:soundcloud_clone/features/search/domain/usecases/genre_usecase.dart';
import 'package:soundcloud_clone/features/search/presentation/bloc/genre_cubit.dart';

class FakeGenreRepository implements GenreRepository {
  Either<Failure, GenrePageData> fetchResult = const Right(GenrePageData());

  Either<Failure, void> followResult = const Right(null);

  final fetchCalls = <String>[];
  final followCalls = <({String userId, bool follow})>[];

  @override
  Future<Either<Failure, GenrePageData>> fetchGenrePage(
    String genreQuery,
  ) async {
    fetchCalls.add(genreQuery);
    return fetchResult;
  }

  @override
  Future<Either<Failure, void>> followUser({
    required String userId,
    required bool follow,
  }) async {
    followCalls.add((userId: userId, follow: follow));
    return followResult;
  }
}

void main() {
  late FakeGenreRepository repository;
  late GenreUseCase genreUseCase;
  late FollowUserUseCase followUserUseCase;

  const lowLikesTrack = Track(
    id: 'trk_low',
    title: 'Low Likes',
    artist: 'Artist',
    audioUrl: '',
    likesCount: 10,
  );

  const highLikesTrack = Track(
    id: 'trk_high',
    title: 'High Likes',
    artist: 'Artist',
    audioUrl: '',
    likesCount: 50,
  );

  setUp(() {
    repository = FakeGenreRepository();
    genreUseCase = GenreUseCase(repository);
    followUserUseCase = FollowUserUseCase(repository);
  });

  GenreCubit buildCubit() {
    return GenreCubit(genreUseCase, followUserUseCase);
  }

  group('GenreCubit', () {
    test('initial state is default GenreState', () {
      final cubit = buildCubit();

      expect(cubit.state, const GenreState());

      cubit.close();
    });

    blocTest<GenreCubit, GenreState>(
      'emits loading then loaded data sorted by likesCount descending',
      build: () {
        repository.fetchResult = const Right(
          GenrePageData(
            headerImageUrl: 'https://cdn.test/header.jpg',
            trending: [lowLikesTrack, highLikesTrack],
            discoverMore: [lowLikesTrack],
            followingIds: {'usr_1'},
          ),
        );

        return buildCubit();
      },
      act: (cubit) => cubit.load('electronic'),
      expect: () => [
        const GenreState(isLoading: true),
        isA<GenreState>()
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.hasError, 'hasError', false)
            .having(
              (state) => state.headerImageUrl,
              'headerImageUrl',
              'https://cdn.test/header.jpg',
            )
            .having(
          (state) => state.trending.map((track) => track.id).toList(),
          'sorted trending ids',
          ['trk_high', 'trk_low'],
        ).having(
          (state) => state.discoverMore.map((track) => track.id).toList(),
          'discoverMore ids',
          ['trk_low'],
        ).having(
          (state) => state.followingIds,
          'followingIds',
          {'usr_1'},
        ),
      ],
      verify: (_) {
        expect(repository.fetchCalls, ['electronic']);
      },
    );

    blocTest<GenreCubit, GenreState>(
      'emits loading then error when load fails',
      build: () {
        repository.fetchResult = const Left(ServerFailure('Failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.load('lo-fi'),
      expect: () => [
        const GenreState(isLoading: true),
        isA<GenreState>()
            .having((state) => state.isLoading, 'isLoading', false)
            .having((state) => state.hasError, 'hasError', true),
      ],
    );

    blocTest<GenreCubit, GenreState>(
      'retry does nothing before a query is loaded',
      build: buildCubit,
      act: (cubit) => cubit.retry(),
      expect: () => <GenreState>[],
      verify: (_) {
        expect(repository.fetchCalls, isEmpty);
      },
    );

    blocTest<GenreCubit, GenreState>(
      'retry reloads last query',
      build: () {
        repository.fetchResult = const Right(GenrePageData());
        return buildCubit();
      },
      act: (cubit) async {
        await cubit.load('hip-hop');
        cubit.retry();
      },
      wait: const Duration(milliseconds: 10),
      verify: (_) {
        expect(repository.fetchCalls, ['hip-hop', 'hip-hop']);
      },
    );

    blocTest<GenreCubit, GenreState>(
      'toggleFollow follows optimistically when not currently following',
      build: buildCubit,
      seed: () => const GenreState(followingIds: {'usr_1'}),
      act: (cubit) => cubit.toggleFollow('usr_2'),
      expect: () => [
        const GenreState(followingIds: {'usr_1', 'usr_2'}),
      ],
      verify: (_) {
        expect(repository.followCalls, [(userId: 'usr_2', follow: true)]);
      },
    );

    blocTest<GenreCubit, GenreState>(
      'toggleFollow unfollows optimistically when currently following',
      build: buildCubit,
      seed: () => const GenreState(followingIds: {'usr_1', 'usr_2'}),
      act: (cubit) => cubit.toggleFollow('usr_2'),
      expect: () => [
        const GenreState(followingIds: {'usr_1'}),
      ],
      verify: (_) {
        expect(repository.followCalls, [(userId: 'usr_2', follow: false)]);
      },
    );

    blocTest<GenreCubit, GenreState>(
      'toggleFollow rolls back when follow request fails',
      build: () {
        repository.followResult = const Left(ServerFailure('Follow failed'));
        return buildCubit();
      },
      seed: () => const GenreState(followingIds: {'usr_1'}),
      act: (cubit) => cubit.toggleFollow('usr_2'),
      expect: () => [
        const GenreState(followingIds: {'usr_1', 'usr_2'}),
        const GenreState(followingIds: {'usr_1'}),
      ],
    );

    blocTest<GenreCubit, GenreState>(
      'toggleFollow ignores empty user id',
      build: buildCubit,
      act: (cubit) => cubit.toggleFollow('   '),
      expect: () => <GenreState>[],
      verify: (_) {
        expect(repository.followCalls, isEmpty);
      },
    );
  });
}
