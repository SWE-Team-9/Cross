import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/errors/failure.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/track_details.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_by_secret_use_case.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_state.dart';
import 'package:get_it/get_it.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';

class MockGetTrackDetailUseCase extends Mock implements GetTrackDetailUseCase {}

class MockOfflineCubit extends Mock implements OfflineCubit {}

class MockGetTrackBySecretUseCase extends Mock
    implements GetTrackBySecretUseCase {}

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class FakeTrack extends Fake implements Track {}

TrackDetail makeDetail(String id) {
  return TrackDetail(
    trackId: id,
    title: 'Song $id',
    artist: 'Artist',
    artistId: 'a1',
    artistHandle: 'artist',
    streamUrl: 'https://cdn/$id.mp3',
  );
}

void main() {
  late MockGetTrackDetailUseCase getByTrackId;
  late MockGetTrackBySecretUseCase getBySecret;
  late MockAudioPlayerService audioService;
  late PlayerCubit playerCubit;

  setUpAll(() {
    registerFallbackValue(FakeTrack());
    registerFallbackValue(<Track>[]);
  });

  late MockOfflineCubit mockOfflineCubit;

  setUp(() {
    getByTrackId = MockGetTrackDetailUseCase();
    getBySecret = MockGetTrackBySecretUseCase();
    audioService = MockAudioPlayerService();
    mockOfflineCubit = MockOfflineCubit();

    // ✅ Register OfflineCubit
    if (GetIt.I.isRegistered<OfflineCubit>()) {
      GetIt.I.unregister<OfflineCubit>();
    }
    GetIt.I.registerSingleton<OfflineCubit>(mockOfflineCubit);

    // default offline behavior
    when(() => mockOfflineCubit.isDownloaded(any())).thenReturn(false);
    when(() => mockOfflineCubit.getPath(any())).thenReturn(null);

    when(() => audioService.playerStateStream)
        .thenAnswer((_) => const Stream<PlayerState>.empty());

    when(() => audioService.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});

    playerCubit = PlayerCubit(audioService);
  });

  tearDown(() {
    GetIt.I.reset();
  });

  TrackLoaderCubit buildCubit() => TrackLoaderCubit(
        getTrackDetail: getByTrackId,
        getTrackBySecret: getBySecret,
        playerCubit: playerCubit,
      );

  group('TrackLoaderCubit', () {
    test('initial state is TrackLoaderIdle', () {
      expect(buildCubit().state, isA<TrackLoaderIdle>());
    });

    blocTest<TrackLoaderCubit, TrackLoaderState>(
      'loadByTrackId emits error for empty track id',
      build: buildCubit,
      act: (cubit) => cubit.loadByTrackId(''),
      expect: () => [
        const TrackLoaderError(message: 'Invalid track link.'),
      ],
    );

    blocTest<TrackLoaderCubit, TrackLoaderState>(
      'loadByTrackId emits ready and plays track on success',
      build: () {
        when(() => getByTrackId('t1')).thenAnswer(
          (_) async => (detail: makeDetail('t1'), failure: null),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadByTrackId('t1'),
      expect: () => [
        const TrackLoaderLoading(),
        isA<TrackLoaderReady>()
            .having((s) => s.detail.trackId, 'trackId', 't1'),
      ],
      verify: (_) {
        verify(() => audioService.playFromContext(
              tracks: any(named: 'tracks'),
              startIndex: 0,
              source: 'single',
            )).called(1);
      },
    );

    blocTest<TrackLoaderCubit, TrackLoaderState>(
      'loadByTrackId maps domain failures to user message',
      build: () {
        when(() => getByTrackId('t1')).thenAnswer(
          (_) async => (
            detail: null,
            failure: const ForbiddenFailure('forbidden'),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadByTrackId('t1'),
      expect: () => [
        const TrackLoaderLoading(),
        const TrackLoaderError(
          message: 'This track is not available for playback.',
        ),
      ],
    );

    blocTest<TrackLoaderCubit, TrackLoaderState>(
      'loadBySecretToken emits error for empty token',
      build: buildCubit,
      act: (cubit) => cubit.loadBySecretToken(''),
      expect: () => [
        const TrackLoaderError(message: 'Invalid share link.'),
      ],
    );

    blocTest<TrackLoaderCubit, TrackLoaderState>(
      'loadBySecretToken success path',
      build: () {
        when(() => getBySecret('s1')).thenAnswer(
          (_) async => (detail: makeDetail('t2'), failure: null),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadBySecretToken('s1'),
      expect: () => [
        const TrackLoaderLoading(),
        isA<TrackLoaderReady>()
            .having((s) => s.detail.trackId, 'trackId', 't2'),
      ],
    );

    blocTest<TrackLoaderCubit, TrackLoaderState>(
      'loadBySecretToken maps unknown error message',
      build: () {
        when(() => getBySecret('s1')).thenAnswer(
          (_) async => (
            detail: null,
            failure: const ServerFailure('x'),
          ),
        );
        return buildCubit();
      },
      act: (cubit) => cubit.loadBySecretToken('s1'),
      expect: () => [
        const TrackLoaderLoading(),
        const TrackLoaderError(
          message: 'Something went wrong. Please try again.',
        ),
      ],
    );
  });
}
