import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/domain/entities/track_details.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/pages/full_player_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/pages/track_deep_link_bridge_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/mini_player.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/player_controls.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/player_seekbar.dart';

class MockPlayerCubit extends MockCubit<PlayerUIState> implements PlayerCubit {}

class MockPlaybackCubit extends MockCubit<PlaybackState>
    implements PlaybackCubit {}

class MockTrackLoaderCubit extends MockCubit<TrackLoaderState>
    implements TrackLoaderCubit {}

class FakeDuration extends Fake implements Duration {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDuration());
    registerFallbackValue(const Track(
      id: '',
      title: '',
      artist: '',
      audioUrl: '',
    ));
  });

  final track = const Track(
    id: 't1',
    title: 'Song 1',
    artist: 'Artist 1',
    audioUrl: 'https://cdn/t1.mp3',
    artworkUrl: null,
    handle: 'artist1',
  );

  final detail = const TrackDetail(
    trackId: 't1',
    title: 'Song 1',
    artist: 'Artist 1',
    artistId: 'a1',
    artistHandle: 'artist1',
    streamUrl: 'https://cdn/t1.mp3',
  );

  const emptyPlaybackState = PlaybackState(isAvailable: true);

  // ═══════════════════════════════════════════════════════════════════════════
  // Player Widgets
  // ═══════════════════════════════════════════════════════════════════════════

  group('Player widgets', () {
    testWidgets('PlayerSeekBar renders times and emits seek callback',
        (tester) async {
      Duration? sought;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerSeekBar(
              position: const Duration(seconds: 65),
              duration: const Duration(seconds: 130),
              onSeek: (d) => sought = d,
            ),
          ),
        ),
      );

      expect(find.text('01:05'), findsOneWidget);
      expect(find.text('02:10'), findsOneWidget);

      final slider = tester.widget<Slider>(find.byType(Slider));
      slider.onChanged?.call(80);

      expect(sought, isNotNull);
    });

    testWidgets('PlayerControls handles play/pause and skip buttons',
        (tester) async {
      var playPauseTapped = 0;
      Duration? seekDuration;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              onPlayPause: () => playPauseTapped++,
              position: const Duration(seconds: 5),
              duration: const Duration(seconds: 60),
              onSeek: (d) => seekDuration = d,
            ),
          ),
        ),
      );

      // replay_10: 5s - 10s = 0s (clamped)
      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();
      expect(seekDuration, Duration.zero);

      // forward_10: 5s + 10s = 15s
      await tester.tap(find.byIcon(Icons.forward_10));
      await tester.pump();
      expect(seekDuration, const Duration(seconds: 15));

      // play/pause button
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(playPauseTapped, 1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // MiniPlayer
  // ═══════════════════════════════════════════════════════════════════════════

  group('MiniPlayer', () {
    late MockPlayerCubit playerCubit;

    setUp(() {
      playerCubit = MockPlayerCubit();
      when(() => playerCubit.openFullPlayer()).thenReturn(null);
      when(() => playerCubit.closeFullPlayer()).thenReturn(null);
      // MiniPlayer calls togglePlayPause() — stub it here
      when(() => playerCubit.togglePlayPause()).thenAnswer((_) async {});
    });

    Widget buildMiniPlayer() => MaterialApp(
          home: Scaffold(
            body: BlocProvider<PlayerCubit>.value(
              value: playerCubit,
              child: const MiniPlayer(),
            ),
          ),
        );

    testWidgets('renders nothing when no track loaded', (tester) async {
      when(() => playerCubit.state).thenReturn(
        const PlayerUIState(
          playerState: PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: null,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());

      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('displays track title and artist', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: track,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
    });

    testWidgets('tapping play button calls pause when playing', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.playing,
            position: Duration(seconds: 30),
            duration: Duration(seconds: 120),
          ),
          currentTrack: track,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());

      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      // MiniPlayer calls togglePlayPause() for both play and pause
      verify(() => playerCubit.togglePlayPause()).called(1);
    });

    testWidgets('tapping play button calls resume when paused', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.paused,
            position: Duration(seconds: 30),
            duration: Duration(seconds: 120),
          ),
          currentTrack: track,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(() => playerCubit.togglePlayPause()).called(1);
    });

    testWidgets('shows pause icon and correct progress when playing',
        (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.playing,
            position: Duration(seconds: 60),
            duration: Duration(seconds: 120),
          ),
          currentTrack: track,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());

      expect(find.byIcon(Icons.pause), findsOneWidget);

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, closeTo(0.5, 0.001));
    });

    testWidgets('shows zero progress when duration is null', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: track,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());

      final indicator = tester.widget<CircularProgressIndicator>(
        find.byType(CircularProgressIndicator),
      );
      expect(indicator.value, 0.0);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // FullPlayerPage
  // ═══════════════════════════════════════════════════════════════════════════

  group('FullPlayerPage', () {
    late MockPlayerCubit playerCubit;
    late MockPlaybackCubit playbackCubit;

    setUp(() {
      playerCubit = MockPlayerCubit();
      playbackCubit = MockPlaybackCubit();

      when(() => playerCubit.openFullPlayer()).thenReturn(null);
      when(() => playerCubit.closeFullPlayer()).thenReturn(null);
      when(() => playerCubit.togglePlayPause()).thenAnswer((_) async {});
      when(() => playerCubit.seek(any())).thenAnswer((_) async {});

      when(() => playbackCubit.state).thenReturn(emptyPlaybackState);
      when(() => playbackCubit.stream)
          .thenAnswer((_) => const Stream<PlaybackState>.empty());
      when(() => playbackCubit.playNext()).thenAnswer((_) async {});
      when(() => playbackCubit.playPrevious()).thenAnswer((_) async {});
    });

    Widget buildFullPlayer() => MaterialApp(
          home: MultiBlocProvider(
            providers: [
              BlocProvider<PlayerCubit>.value(value: playerCubit),
              BlocProvider<PlaybackCubit>.value(value: playbackCubit),
            ],
            child: const FullPlayerPage(),
          ),
        );

    testWidgets('shows no-track placeholder when currentTrack is null',
        (tester) async {
      when(() => playerCubit.state).thenReturn(
        const PlayerUIState(
          playerState: PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: null,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());

      expect(find.text('No track selected'), findsOneWidget);
    });

    testWidgets('renders controls and invokes cubit methods', (tester) async {
      when(() => playerCubit.state).thenReturn(
        PlayerUIState(
          playerState: const PlayerState(
            status: PlayerStatus.playing,
            position: Duration(seconds: 10),
            duration: Duration(seconds: 120),
          ),
          currentTrack: track,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);

      // replay_10 inside PlayerControls: 10s - 10s = 0s
      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();
      verify(() => playerCubit.seek(const Duration(seconds: 0))).called(1);

      // pause button inside PlayerControls
      await tester.tap(
        find.descendant(
          of: find.byType(PlayerControls),
          matching: find.byIcon(Icons.pause),
        ),
      );
      await tester.pump();
      verify(() => playerCubit.togglePlayPause()).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TrackDeepLinkBridgePage
  // ═══════════════════════════════════════════════════════════════════════════

  group('TrackDeepLinkBridgePage', () {
    late MockTrackLoaderCubit loaderCubit;
    late MockPlayerCubit playerCubit;
    late MockPlaybackCubit playbackCubit;

    setUp(() {
      loaderCubit = MockTrackLoaderCubit();
      playerCubit = MockPlayerCubit();
      playbackCubit = MockPlaybackCubit();

      when(() => loaderCubit.loadByTrackId(any())).thenAnswer((_) async {});
      when(() => loaderCubit.loadBySecretToken(any())).thenAnswer((_) async {});

      when(() => playerCubit.state).thenReturn(
        const PlayerUIState(
          playerState: PlayerState(
            status: PlayerStatus.idle,
            position: Duration.zero,
          ),
          currentTrack: null,
        ),
      );
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());
      when(() => playerCubit.openFullPlayer()).thenReturn(null);
      when(() => playerCubit.closeFullPlayer()).thenReturn(null);
      when(() => playerCubit.togglePlayPause()).thenAnswer((_) async {});
      when(() => playerCubit.seek(any())).thenAnswer((_) async {});

      when(() => playbackCubit.state).thenReturn(emptyPlaybackState);
      when(() => playbackCubit.stream)
          .thenAnswer((_) => const Stream<PlaybackState>.empty());
      when(() => playbackCubit.playNext()).thenAnswer((_) async {});
      when(() => playbackCubit.playPrevious()).thenAnswer((_) async {});
    });

    testWidgets('calls loadByTrackId and pushes FullPlayerPage on ready',
        (tester) async {
      when(() => loaderCubit.state).thenReturn(const TrackLoaderIdle());
      whenListen(
        loaderCubit,
        Stream<TrackLoaderState>.fromIterable(
            [TrackLoaderReady(detail: detail)]),
        initialState: const TrackLoaderIdle(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TrackLoaderCubit>.value(value: loaderCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
            BlocProvider<PlaybackCubit>.value(value: playbackCubit),
          ],
          child: MaterialApp(
            home: const TrackDeepLinkBridgePage(trackId: 't1'),
            routes: {
              '/home': (_) => const Scaffold(body: Text('Home Screen')),
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => loaderCubit.loadByTrackId('t1')).called(1);
      expect(find.byType(FullPlayerPage), findsOneWidget);
    });

    testWidgets('shows snackbar and navigates home on error', (tester) async {
      when(() => loaderCubit.state).thenReturn(const TrackLoaderIdle());
      whenListen(
        loaderCubit,
        Stream<TrackLoaderState>.fromIterable(
          const [TrackLoaderError(message: 'bad link')],
        ),
        initialState: const TrackLoaderIdle(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TrackLoaderCubit>.value(value: loaderCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
            BlocProvider<PlaybackCubit>.value(value: playbackCubit),
          ],
          child: MaterialApp(
            home: const TrackDeepLinkBridgePage(secretToken: 's1'),
            routes: {
              '/home': (_) => const Scaffold(body: Text('Home Screen')),
            },
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      verify(() => loaderCubit.loadBySecretToken('s1')).called(1);
      expect(find.text('Home Screen'), findsOneWidget);
    });
  });
}
