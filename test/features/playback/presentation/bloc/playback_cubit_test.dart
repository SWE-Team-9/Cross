import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_state.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}
class FakeTrack extends Fake implements Track {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _t1 = Track(id: 't1', title: 'Track 1', artist: 'Artist 1', audioUrl: 'url1');
const _t2 = Track(id: 't2', title: 'Track 2', artist: 'Artist 2', audioUrl: 'url2');
const _t3 = Track(id: 't3', title: 'Track 3', artist: 'Artist 3', audioUrl: 'url3');
const _queue = [_t1, _t2, _t3];

void main() {
  late MockAudioPlayerService audioService;

  setUpAll(() {
    registerFallbackValue(FakeTrack());
    registerFallbackValue(Duration.zero);
  });

  setUp(() {
    audioService = MockAudioPlayerService();
    when(() => audioService.play(any())).thenAnswer((_) async {});
    when(() => audioService.pause()).thenAnswer((_) async {});
    when(() => audioService.resume()).thenAnswer((_) async {});
    when(() => audioService.stop()).thenAnswer((_) async {});
    when(() => audioService.seek(any())).thenAnswer((_) async {});
  });

  PlaybackCubit makeCubit() => PlaybackCubit(audioService);

  // ═══════════════════════════════════════════════════════════════════════════
  // Initial state
  // ═══════════════════════════════════════════════════════════════════════════

  test('initial state is empty and available', () {
    final cubit = makeCubit();
    expect(cubit.state.isAvailable, isTrue);
    expect(cubit.state.isPlaying, isFalse);
    expect(cubit.state.currentTrack, isNull);
    expect(cubit.state.queue, isEmpty);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // playTrack
  // ═══════════════════════════════════════════════════════════════════════════

  group('playTrack', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'plays track found in queue and emits isPlaying',
      build: makeCubit,
      act: (c) => c.playTrack(_t2, _queue),
      expect: () => [
        isA<PlaybackState>()
            .having((s) => s.currentTrack, 'currentTrack', _t2)
            .having((s) => s.isPlaying, 'isPlaying', isTrue)
            .having((s) => s.queue, 'queue', _queue),
      ],
      verify: (_) => verify(() => audioService.play(_t2)).called(1),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'defaults to first track when track not found in queue',
      build: makeCubit,
      act: (c) => c.playTrack(
        const Track(id: 'unknown', title: 'X', artist: 'Y', audioUrl: 'u'),
        _queue,
      ),
      expect: () => [
        isA<PlaybackState>()
            .having((s) => s.currentTrack, 'currentTrack', _t1)
            .having((s) => s.isPlaying, 'isPlaying', isTrue),
      ],
      verify: (_) => verify(() => audioService.play(_t1)).called(1),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when queue is empty',
      build: makeCubit,
      act: (c) => c.playTrack(_t1, const []),
      expect: () => [],
      verify: (_) => verifyNever(() => audioService.play(any())),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // pause
  // ═══════════════════════════════════════════════════════════════════════════

  group('pause', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'pauses when playing and emits isPlaying=false',
      build: makeCubit,
      seed: () => const PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: _t1,
        queue: _queue,
      ),
      act: (c) => c.pause(),
      expect: () => [
        isA<PlaybackState>().having((s) => s.isPlaying, 'isPlaying', isFalse),
      ],
      verify: (_) => verify(() => audioService.pause()).called(1),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when already paused',
      build: makeCubit,
      seed: () => const PlaybackState(isAvailable: true, isPlaying: false),
      act: (c) => c.pause(),
      expect: () => [],
      verify: (_) => verifyNever(() => audioService.pause()),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // resume
  // ═══════════════════════════════════════════════════════════════════════════

  group('resume', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'resumes when track exists and emits isPlaying=true',
      build: makeCubit,
      seed: () => const PlaybackState(
        isAvailable: true,
        isPlaying: false,
        currentTrack: _t1,
      ),
      act: (c) => c.resume(),
      expect: () => [
        isA<PlaybackState>().having((s) => s.isPlaying, 'isPlaying', isTrue),
      ],
      verify: (_) => verify(() => audioService.play(_t1)).called(1),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when no current track',
      build: makeCubit,
      seed: () => const PlaybackState(isAvailable: true, currentTrack: null),
      act: (c) => c.resume(),
      expect: () => [],
      verify: (_) => verifyNever(() => audioService.play(any())),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // togglePlayPause
  // ═══════════════════════════════════════════════════════════════════════════

  group('togglePlayPause', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'pauses when playing',
      build: makeCubit,
      seed: () => const PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: _t1,
      ),
      act: (c) => c.togglePlayPause(),
      expect: () => [
        isA<PlaybackState>().having((s) => s.isPlaying, 'isPlaying', isFalse),
      ],
      verify: (_) => verify(() => audioService.pause()).called(1),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'resumes when paused',
      build: makeCubit,
      seed: () => const PlaybackState(
        isAvailable: true,
        isPlaying: false,
        currentTrack: _t1,
      ),
      act: (c) => c.togglePlayPause(),
      expect: () => [
        isA<PlaybackState>().having((s) => s.isPlaying, 'isPlaying', isTrue),
      ],
      verify: (_) => verify(() => audioService.play(_t1)).called(1),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // stop
  // ═══════════════════════════════════════════════════════════════════════════

  group('stop', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'stops playback and clears queue and isPlaying',
      build: makeCubit,
      seed: () => const PlaybackState(
        isAvailable: true,
        isPlaying: true,
        currentTrack: _t1,
        queue: _queue,
      ),
      act: (c) => c.stop(),
      expect: () => [
        isA<PlaybackState>()
            .having((s) => s.isPlaying, 'isPlaying', isFalse)

            .having((s) => s.queue, 'queue', isEmpty),
      ],
      verify: (_) => verify(() => audioService.stop()).called(1),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // playNext
  // ═══════════════════════════════════════════════════════════════════════════

  group('playNext', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'advances to next track',
      build: makeCubit,
      act: (c) async {
        await c.playTrack(_t1, _queue); // index=0
        await c.playNext();             // index=1 → _t2
      },
      skip: 1, // skip the playTrack emit
      expect: () => [
        isA<PlaybackState>()
            .having((s) => s.currentTrack, 'currentTrack', _t2)
            .having((s) => s.isPlaying, 'isPlaying', isTrue),
      ],
      verify: (_) => verify(() => audioService.play(_t2)).called(1),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when already at last track',
      build: makeCubit,
      act: (c) async {
        await c.playTrack(_t3, _queue); // index=2 (last)
        await c.playNext();
      },
      skip: 1,
      expect: () => [],
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when queue is empty',
      build: makeCubit,
      act: (c) => c.playNext(),
      expect: () => [],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // playPrevious
  // ═══════════════════════════════════════════════════════════════════════════

  group('playPrevious', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'goes back to previous track',
      build: makeCubit,
      act: (c) async {
        await c.playTrack(_t2, _queue); // index=1
        await c.playPrevious();         // index=0 → _t1
      },
      skip: 1,
      expect: () => [
        isA<PlaybackState>()
            .having((s) => s.currentTrack, 'currentTrack', _t1)
            .having((s) => s.isPlaying, 'isPlaying', isTrue),
      ],
      verify: (_) => verify(() => audioService.play(_t1)).called(greaterThanOrEqualTo(1)),
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when at first track',
      build: makeCubit,
      act: (c) async {
        await c.playTrack(_t1, _queue); // index=0
        await c.playPrevious();
      },
      skip: 1,
      expect: () => [],
    );

    blocTest<PlaybackCubit, PlaybackState>(
      'does nothing when queue is empty',
      build: makeCubit,
      act: (c) => c.playPrevious(),
      expect: () => [],
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // seek
  // ═══════════════════════════════════════════════════════════════════════════

  group('seek', () {
    blocTest<PlaybackCubit, PlaybackState>(
      'delegates to audioService.seek',
      build: makeCubit,
      act: (c) => c.seek(const Duration(seconds: 30)),
      expect: () => [],
      verify: (_) =>
          verify(() => audioService.seek(const Duration(seconds: 30))).called(1),
    );
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // getQueue
  // ═══════════════════════════════════════════════════════════════════════════

  test('getQueue returns current queue', () async {
    final cubit = makeCubit();
    await cubit.playTrack(_t1, _queue);
    expect(cubit.getQueue(), _queue);
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // addPlayNext
  // ═══════════════════════════════════════════════════════════════════════════

  group('addPlayNext', () {
    test('inserts track right after current when playing', () async {
      final cubit = makeCubit();
      await cubit.playTrack(_t1, [_t1, _t3]); // index=0
      cubit.addPlayNext(_t2);

      expect(cubit.state.queue, [_t1, _t2, _t3]);
    });

    test('puts track at front when nothing is playing', () {
      final cubit = makeCubit();
      cubit.addPlayNext(_t1);

      expect(cubit.state.queue.first, _t1);
    });

    test('removes duplicate before inserting', () async {
      final cubit = makeCubit();
      await cubit.playTrack(_t1, [_t1, _t2, _t3]); // index=0
      cubit.addPlayNext(_t2); // _t2 already in queue at index=1

      // _t2 removed then re-inserted at index=1 (right after _t1)
      expect(cubit.state.queue, [_t1, _t2, _t3]);
    });

    test('emits updated queue', () async {
      final cubit = makeCubit();
      await cubit.playTrack(_t1, [_t1, _t3]);
      cubit.addPlayNext(_t2);

      expect(cubit.state.queue.length, 3);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // addPlayLast
  // ═══════════════════════════════════════════════════════════════════════════

  group('addPlayLast', () {
    test('appends track to end of queue', () async {
      final cubit = makeCubit();
      await cubit.playTrack(_t1, [_t1, _t2]);
      cubit.addPlayLast(_t3);

      expect(cubit.state.queue.last, _t3);
      expect(cubit.state.queue.length, 3);
    });

    test('removes duplicate before appending', () async {
      final cubit = makeCubit();
      await cubit.playTrack(_t1, [_t1, _t2, _t3]);
      cubit.addPlayLast(_t2); // _t2 already in queue

      expect(cubit.state.queue.last, _t2);
      expect(cubit.state.queue.length, 3);
    });

    test('works when queue is empty', () {
      final cubit = makeCubit();
      cubit.addPlayLast(_t1);

      expect(cubit.state.queue, [_t1]);
    });

    test('updates currentIndex correctly after removing track before current',
        () async {
      final cubit = makeCubit();
      // Play _t2 (index=1), then addPlayLast _t1 (index=0, before current)
      // After removing _t1, _t2 shifts to index=0 — cubit should fix index
      await cubit.playTrack(_t2, [_t1, _t2, _t3]);
      cubit.addPlayLast(_t1);

      // Queue: [_t2, _t3, _t1]
      expect(cubit.state.queue, [_t2, _t3, _t1]);
      expect(cubit.state.currentTrack, _t2);
    });
  });
}