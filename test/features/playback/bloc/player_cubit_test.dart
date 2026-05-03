import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/track_details.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/waveform_data.dart';
import 'package:soundcloud_clone/features/playback/domain/usecases/get_track_detail_use_case.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:get_it/get_it.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockOfflineCubit extends Mock implements OfflineCubit {}

class MockGetTrackDetailUseCase extends Mock implements GetTrackDetailUseCase {}

class FakeTrack extends Fake implements Track {}

void main() {
  late MockAudioPlayerService mockService;
  late PlayerCubit cubit;
  setUpAll(() {
    registerFallbackValue(FakeTrack());
    registerFallbackValue(<Track>[]);
    registerFallbackValue(Duration.zero);
    registerFallbackValue(AppRepeatMode.off);
  });

  final testTrack = const Track(
    id: '1',
    title: 'Test Track',
    artist: 'Test Artist',
    audioUrl: 'https://test.com/audio.mp3',
  );

  final nextTrack = const Track(
    id: '2',
    title: 'Next Track',
    artist: 'Next Artist',
    audioUrl: 'https://test.com/next.mp3',
  );

  final thirdTrack = const Track(
    id: '3',
    title: 'Third Track',
    artist: 'Third Artist',
    audioUrl: 'https://test.com/third.mp3',
  );

  late MockOfflineCubit mockOfflineCubit;

  setUp(() {
    mockService = MockAudioPlayerService();
    mockOfflineCubit = MockOfflineCubit();

    if (GetIt.I.isRegistered<OfflineCubit>()) {
      GetIt.I.unregister<OfflineCubit>();
    }

    GetIt.I.registerSingleton<OfflineCubit>(mockOfflineCubit);

    // default offline behavior
    when(() => mockOfflineCubit.isDownloaded(any())).thenReturn(false);
    when(() => mockOfflineCubit.getPath(any())).thenReturn(null);

    when(() => mockService.playerStateStream)
        .thenAnswer((_) => const Stream.empty());

    when(() => mockService.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});

    when(() => mockService.setRepeatMode(any())).thenAnswer((_) async {});
    when(() => mockService.stop()).thenAnswer((_) async {});

    cubit = PlayerCubit(mockService);
  });

  tearDown(() {
    cubit.close();
    GetIt.I.reset();
  });

  group('PlayerCubit', () {
    test('initial state is correct', () {
      expect(cubit.state.currentTrack, isNull);
      expect(cubit.state.playerState.status, PlayerStatus.idle);
    });

    blocTest<PlayerCubit, dynamic>(
      'play() sets current track and calls service',
      build: () {
        when(() => mockService.playFromContext(
              tracks: any(named: 'tracks'),
              startIndex: any(named: 'startIndex'),
              source: any(named: 'source'),
            )).thenAnswer((_) async {});
        return PlayerCubit(mockService);
      },
      act: (cubit) => cubit.play(testTrack),
      expect: () => [
        isA().having(
          (state) => state.currentTrack,
          'currentTrack',
          testTrack,
        ),
      ],
      verify: (_) {
        verify(() => mockService.playFromContext(
              tracks: [testTrack],
              startIndex: 0,
              source: 'single',
            )).called(1);
      },
    );

    blocTest<PlayerCubit, dynamic>(
      'pause() calls audio service pause',
      build: () {
        when(() => mockService.pause()).thenAnswer((_) async {});
        return PlayerCubit(mockService);
      },
      act: (cubit) => cubit.pause(),
      verify: (_) {
        verify(() => mockService.pause()).called(1);
      },
    );

    blocTest<PlayerCubit, dynamic>(
      'resume() calls audio service resume',
      build: () {
        when(() => mockService.resume()).thenAnswer((_) async {});
        return PlayerCubit(mockService);
      },
      act: (cubit) => cubit.resume(),
      verify: (_) {
        verify(() => mockService.resume()).called(1);
      },
    );

    blocTest<PlayerCubit, dynamic>(
      'togglePlayPause() pauses when playing',
      build: () {
        when(() => mockService.pause()).thenAnswer((_) async {});
        when(() => mockService.playerStateStream).thenAnswer(
          (_) => Stream.value(
            const PlayerState(
              status: PlayerStatus.playing,
              position: Duration.zero,
            ),
          ),
        );
        return PlayerCubit(mockService);
      },
      act: (cubit) async {
        await Future.delayed(const Duration(milliseconds: 10));
        await cubit.togglePlayPause();
      },
      verify: (_) {
        verify(() => mockService.pause()).called(1);
      },
    );

    blocTest<PlayerCubit, dynamic>(
      'seek() calls audio service seek',
      build: () {
        when(() => mockService.seek(any())).thenAnswer((_) async {});
        return PlayerCubit(mockService);
      },
      act: (cubit) => cubit.seek(const Duration(seconds: 30)),
      verify: (_) {
        verify(() => mockService.seek(const Duration(seconds: 30))).called(1);
      },
    );

    blocTest<PlayerCubit, dynamic>(
      'stop() calls audio service stop',
      build: () {
        when(() => mockService.stop()).thenAnswer((_) async {});
        return PlayerCubit(mockService);
      },
      act: (cubit) => cubit.stop(),
      verify: (_) {
        verify(() => mockService.stop()).called(1);
      },
    );

    test('stop() clears the current track and hides the mini player', () async {
      await cubit.play(testTrack);

      await cubit.stop();

      expect(cubit.state.currentTrack, isNull);
      expect(cubit.state.playerState.status, PlayerStatus.idle);
      expect(cubit.state.queue, isEmpty);
      expect(cubit.state.showMiniPlayer, isFalse);
      verify(() => mockService.stop()).called(1);
    });

    blocTest<PlayerCubit, dynamic>(
      'togglePlayPause() resumes when not playing',
      build: () {
        when(() => mockService.resume()).thenAnswer((_) async {});
        return PlayerCubit(mockService);
      },
      act: (cubit) => cubit.togglePlayPause(),
      verify: (_) {
        verify(() => mockService.resume()).called(1);
      },
    );

    blocTest<PlayerCubit, dynamic>(
      'openFullPlayer() sets full screen to true',
      build: () => PlayerCubit(mockService),
      act: (cubit) => cubit.openFullPlayer(),
      expect: () => [
        isA().having((state) => state.isFullScreen, 'isFullScreen', isTrue),
      ],
    );

    blocTest<PlayerCubit, dynamic>(
      'closeFullPlayer() sets full screen to false',
      build: () => PlayerCubit(mockService),
      act: (cubit) {
        cubit.openFullPlayer();
        cubit.closeFullPlayer();
      },
      expect: () => [
        isA().having((state) => state.isFullScreen, 'isFullScreen', isTrue),
        isA().having((state) => state.isFullScreen, 'isFullScreen', isFalse),
      ],
    );

    blocTest<PlayerCubit, dynamic>(
      'updates state when stream emits new player state',
      build: () {
        when(() => mockService.playerStateStream).thenAnswer(
          (_) => Stream.value(
            const PlayerState(
              status: PlayerStatus.playing,
              position: Duration(seconds: 10),
            ),
          ),
        );
        return PlayerCubit(mockService);
      },
      expect: () => [
        isA().having(
          (state) => state.playerState.status,
          'status',
          PlayerStatus.playing,
        ),
      ],
    );

    test('addPlayNext inserts into PlayerCubit queue and playNext plays it',
        () async {
      await cubit.play(testTrack);

      await cubit.addPlayNext(nextTrack);

      expect(cubit.state.queue, [testTrack, nextTrack]);
      expect(cubit.state.currentIndex, 0);

      await cubit.playNext();

      expect(cubit.state.currentTrack, nextTrack);
      expect(cubit.state.currentIndex, 1);
      verify(() => mockService.playFromContext(
            tracks: any(named: 'tracks'),
            startIndex: 1,
            source: 'single',
          )).called(1);
    });

    test('addPlayNext starts playback when queue is empty', () async {
      await cubit.addPlayNext(testTrack);

      expect(cubit.state.currentTrack, testTrack);
      expect(cubit.state.currentIndex, 0);
      verify(() => mockService.playFromContext(
            tracks: [testTrack],
            startIndex: 0,
            source: 'queue',
          )).called(1);
    });

    test('playNext returns early when already at last track', () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 1,
        source: 'queue',
      );
      clearInteractions(mockService);

      await cubit.playNext();

      verifyNever(() => mockService.playFromContext(
            tracks: any(named: 'tracks'),
            startIndex: any(named: 'startIndex'),
            source: any(named: 'source'),
          ));
      expect(cubit.state.currentTrack, nextTrack);
      expect(cubit.state.currentIndex, 1);
    });

    test('setRepeatMode updates state and delegates to audio service',
        () async {
      await cubit.setRepeatMode(AppRepeatMode.one);

      expect(cubit.state.repeatMode, AppRepeatMode.one);
      verify(() => mockService.setRepeatMode(AppRepeatMode.one)).called(1);
    });

    test('cycleRepeatMode steps through each repeat mode', () async {
      await cubit.cycleRepeatMode();
      await cubit.cycleRepeatMode();
      await cubit.cycleRepeatMode();

      expect(cubit.state.repeatMode, AppRepeatMode.off);
      verifyInOrder([
        () => mockService.setRepeatMode(AppRepeatMode.one),
        () => mockService.setRepeatMode(AppRepeatMode.all),
        () => mockService.setRepeatMode(AppRepeatMode.off),
      ]);
    });

    test('playNext wraps to first track when repeat queue is enabled',
        () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 1,
        source: 'queue',
      );
      await cubit.setRepeatMode(AppRepeatMode.all);
      clearInteractions(mockService);

      await cubit.playNext();

      expect(cubit.state.currentTrack, testTrack);
      expect(cubit.state.currentIndex, 0);
      verify(() => mockService.playFromContext(
            tracks: [testTrack, nextTrack],
            startIndex: 0,
            source: 'queue',
          )).called(1);
    });

    test('playPrevious plays previous track when available', () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 1,
        source: 'queue',
      );
      clearInteractions(mockService);

      await cubit.playPrevious();

      expect(cubit.state.currentTrack, testTrack);
      expect(cubit.state.currentIndex, 0);
      verify(() => mockService.playFromContext(
            tracks: [testTrack, nextTrack],
            startIndex: 0,
            source: 'queue',
          )).called(1);
    });

    test('playPrevious returns early when current index is zero', () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 0,
        source: 'queue',
      );
      clearInteractions(mockService);

      await cubit.playPrevious();

      verifyNever(() => mockService.playFromContext(
            tracks: any(named: 'tracks'),
            startIndex: any(named: 'startIndex'),
            source: any(named: 'source'),
          ));
      expect(cubit.state.currentTrack, testTrack);
      expect(cubit.state.currentIndex, 0);
    });

    test('playPrevious wraps to last track when repeat queue is enabled',
        () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 0,
        source: 'queue',
      );
      await cubit.setRepeatMode(AppRepeatMode.all);
      clearInteractions(mockService);

      await cubit.playPrevious();

      expect(cubit.state.currentTrack, nextTrack);
      expect(cubit.state.currentIndex, 1);
      verify(() => mockService.playFromContext(
            tracks: [testTrack, nextTrack],
            startIndex: 1,
            source: 'queue',
          )).called(1);
    });

    test('addPlayLast appends track without restarting playback', () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 0,
        source: 'queue',
      );
      clearInteractions(mockService);

      await cubit.addPlayLast(thirdTrack);

      expect(cubit.state.queue, [testTrack, nextTrack, thirdTrack]);
      expect(cubit.state.currentIndex, 0);
      verifyNever(() => mockService.playFromContext(
            tracks: any(named: 'tracks'),
            startIndex: any(named: 'startIndex'),
            source: any(named: 'source'),
          ));
    });

    test('addPlayLast does nothing when adding currently playing track',
        () async {
      await cubit.play(testTrack);
      clearInteractions(mockService);

      await cubit.addPlayLast(testTrack);

      expect(cubit.state.queue, [testTrack]);
      expect(cubit.state.currentIndex, 0);
      verifyNever(() => mockService.playFromContext(
            tracks: any(named: 'tracks'),
            startIndex: any(named: 'startIndex'),
            source: any(named: 'source'),
          ));
    });

    test('addPlayLast starts playback when queue is empty', () async {
      await cubit.addPlayLast(testTrack);

      expect(cubit.state.currentTrack, testTrack);
      expect(cubit.state.queue, [testTrack]);
      verify(() => mockService.playFromContext(
            tracks: [testTrack],
            startIndex: 0,
            source: 'queue',
          )).called(1);
    });

    test('playFromContext clamps out-of-range start index', () async {
      await cubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 99,
        source: 'queue',
      );

      expect(cubit.state.currentTrack, nextTrack);
      expect(cubit.state.currentIndex, 1);
      verify(() => mockService.playFromContext(
            tracks: [testTrack, nextTrack],
            startIndex: 1,
            source: 'queue',
          )).called(1);
    });

    test('playFromContext passes downloaded local path to audio service',
        () async {
      when(() => mockOfflineCubit.isDownloaded('1')).thenReturn(true);
      when(() => mockOfflineCubit.getPath('1')).thenReturn('/offline/1.mp3');

      await cubit.play(testTrack);

      final captured = verify(() => mockService.playFromContext(
            tracks: captureAny(named: 'tracks'),
            startIndex: 0,
            source: 'single',
          )).captured.single as List<Track>;

      expect(captured.single.localPath, '/offline/1.mp3');
      expect(cubit.state.currentTrack?.localPath, '/offline/1.mp3');
    });

    test('playFromContext works when offline cubit is not registered',
        () async {
      await GetIt.I.unregister<OfflineCubit>();
      final localCubit = PlayerCubit(mockService);
      addTearDown(localCubit.close);

      await localCubit.play(testTrack);

      expect(localCubit.state.currentTrack, testTrack);
      verify(() => mockService.playFromContext(
            tracks: [testTrack],
            startIndex: 0,
            source: 'single',
          )).called(1);
    });

    test('playFromContext resolves missing audio url from track details',
        () async {
      final getTrackDetail = MockGetTrackDetailUseCase();
      final trackWithoutAudio = Track(
        id: testTrack.id,
        title: testTrack.title,
        artist: testTrack.artist,
        audioUrl: '',
      );
      final detail = TrackDetail(
        trackId: testTrack.id,
        title: 'Resolved',
        artist: 'Resolved Artist',
        artistId: 'artist-1',
        artistHandle: 'resolved',
        streamUrl: 'https://cdn/resolved.mp3',
        waveformData: WaveformData.fromRaw(const [0.2, 0.4, 0.8]),
      );

      when(() => getTrackDetail(testTrack.id)).thenAnswer(
        (_) async => (detail: detail, failure: null),
      );

      final localCubit = PlayerCubit(
        mockService,
        getTrackDetail: getTrackDetail,
      );
      addTearDown(localCubit.close);

      await localCubit.play(trackWithoutAudio);

      final captured = verify(() => mockService.playFromContext(
            tracks: captureAny(named: 'tracks'),
            startIndex: 0,
            source: 'single',
          )).captured.single as List<Track>;

      expect(localCubit.state.waveform?.normalizedPeaks, isNotEmpty);
      expect(captured.single.audioUrl, 'https://cdn/resolved.mp3');
      expect(captured.single.title, 'Resolved');
    });

    test('player stream keeps local queue during a pending track switch',
        () async {
      final controller = StreamController<PlayerState>();
      when(() => mockService.playerStateStream).thenAnswer(
        (_) => controller.stream,
      );

      final localCubit = PlayerCubit(mockService);
      addTearDown(() async {
        await localCubit.close();
        await controller.close();
      });

      await localCubit.playFromContext(
        tracks: [testTrack, nextTrack],
        startIndex: 1,
        source: 'queue',
      );

      controller.add(
        PlayerState(
          status: PlayerStatus.playing,
          position: Duration.zero,
          currentTrackId: testTrack.id,
          queue: <Track>[testTrack],
          currentIndex: 0,
        ),
      );
      await Future<void>.delayed(Duration.zero);

      expect(localCubit.state.queue, [testTrack, nextTrack]);
      expect(localCubit.state.currentIndex, 1);
    });

    test('hideMiniPlayer and showMiniPlayer toggle mini-player visibility', () {
      expect(cubit.state.showMiniPlayer, isTrue);

      cubit.hideMiniPlayer();
      expect(cubit.state.showMiniPlayer, isFalse);

      cubit.showMiniPlayer();
      expect(cubit.state.showMiniPlayer, isTrue);
    });

    test('setVolume delegates to audio service', () async {
      when(() => mockService.setVolume(any())).thenAnswer((_) async {});

      await cubit.setVolume(0.25);

      verify(() => mockService.setVolume(0.25)).called(1);
    });

    test('playFromContext returns early on empty track list', () async {
      await cubit.playFromContext(tracks: const [], startIndex: 0);

      verifyNever(() => mockService.playFromContext(
            tracks: any(named: 'tracks'),
            startIndex: any(named: 'startIndex'),
            source: any(named: 'source'),
          ));
      expect(cubit.state.currentTrack, isNull);
    });
  });
}
