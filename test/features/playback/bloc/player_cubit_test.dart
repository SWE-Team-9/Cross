import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class FakeTrack extends Fake implements Track {}

void main() {
  late MockAudioPlayerService mockService;
  late PlayerCubit cubit;
  setUpAll(() {
    registerFallbackValue(FakeTrack());
    registerFallbackValue(Duration.zero);
  });

  final testTrack = const Track(
    id: '1',
    title: 'Test Track',
    artist: 'Test Artist',
    audioUrl: 'https://test.com/audio.mp3',
  );

  setUp(() {
    mockService = MockAudioPlayerService();

    when(() => mockService.playerStateStream)
        .thenAnswer((_) => const Stream.empty());

    cubit = PlayerCubit(mockService);
  });

  tearDown(() {
    cubit.close();
  });

  group('PlayerCubit', () {
    test('initial state is correct', () {
      expect(cubit.state.currentTrack, isNull);
      expect(cubit.state.playerState.status, PlayerStatus.idle);
    });

    blocTest<PlayerCubit, dynamic>(
      'play() sets current track and calls service',
      build: () {
        when(() => mockService.play(any())).thenAnswer((_) async {});
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
        verify(() => mockService.play(testTrack)).called(1);
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
  });
}
