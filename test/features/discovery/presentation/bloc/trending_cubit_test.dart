import 'package:bloc_test/bloc_test.dart';
import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/features/discovery/domain/entities/trending_track.dart';
import 'package:soundcloud_clone/features/discovery/domain/repositories/trending_repository.dart';
import 'package:soundcloud_clone/features/discovery/domain/usecases/get_trending_usecase.dart';
import 'package:soundcloud_clone/features/discovery/presentation/bloc/trending_cubit.dart';

class FakeTrendingRepository implements TrendingRepository {
  Either<Failure, List<TrendingTrack>> result = const Right([]);

  int? receivedLimit;
  int? receivedWindowDays;

  @override
  Future<Either<Failure, List<TrendingTrack>>> getTrending({
    int limit = 20,
    int windowDays = 7,
  }) async {
    receivedLimit = limit;
    receivedWindowDays = windowDays;

    return result;
  }
}

void main() {
  late FakeTrendingRepository repository;
  late GetTrendingUseCase useCase;

  const track = TrendingTrack(
    id: 'trk_1',
    title: 'Layali',
    genre: 'electronic',
    audioUrl: 'https://cdn.test/audio.mp3',
    coverUrl: 'https://cdn.test/cover.jpg',
    trendingScore: 98.5,
    playCount: 100,
    likesCount: 20,
    repostsCount: 3,
    ownerHandle: 'ali-beats',
    ownerDisplayName: 'Ali Beats',
    ownerId: 'usr_1',
  );

  setUp(() {
    repository = FakeTrendingRepository();
    useCase = GetTrendingUseCase(repository);
  });

  TrendingCubit buildCubit() {
    return TrendingCubit(getTrendingUseCase: useCase);
  }

  group('TrendingCubit', () {
    test('initial state is TrendingInitial', () {
      final cubit = buildCubit();

      expect(cubit.state, isA<TrendingInitial>());

      cubit.close();
    });

    blocTest<TrendingCubit, TrendingState>(
      'emits loading then loaded when getTrending succeeds',
      build: () {
        repository.result = const Right([track]);
        return buildCubit();
      },
      act: (cubit) => cubit.loadTrending(),
      expect: () => [
        isA<TrendingLoading>(),
        isA<TrendingLoaded>().having(
          (state) => state.tracks,
          'tracks',
          [track],
        ),
      ],
      verify: (_) {
        expect(repository.receivedLimit, 20);
        expect(repository.receivedWindowDays, 7);
      },
    );

    blocTest<TrendingCubit, TrendingState>(
      'passes custom limit and windowDays to use case',
      build: () {
        repository.result = const Right([track]);
        return buildCubit();
      },
      act: (cubit) => cubit.loadTrending(limit: 10, windowDays: 30),
      verify: (_) {
        expect(repository.receivedLimit, 10);
        expect(repository.receivedWindowDays, 30);
      },
    );

    blocTest<TrendingCubit, TrendingState>(
      'emits loading then error when getTrending fails',
      build: () {
        repository.result = const Left(ServerFailure('Trending failed'));
        return buildCubit();
      },
      act: (cubit) => cubit.loadTrending(),
      expect: () => [
        isA<TrendingLoading>(),
        isA<TrendingError>().having(
          (state) => state.message,
          'message',
          'Trending failed',
        ),
      ],
    );
  });
}
