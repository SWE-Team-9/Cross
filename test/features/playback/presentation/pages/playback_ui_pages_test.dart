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
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/track_loader_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/pages/full_player_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/pages/track_deep_link_bridge_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/player_controls.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/player_seekbar.dart';

class MockPlayerCubit extends MockCubit<PlayerUIState> implements PlayerCubit {}

class MockTrackLoaderCubit extends MockCubit<TrackLoaderState>
    implements TrackLoaderCubit {}

class FakeDuration extends Fake implements Duration {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDuration());
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

      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();
      expect(seekDuration, Duration.zero);

      await tester.tap(find.byIcon(Icons.forward_10));
      await tester.pump();
      expect(seekDuration, const Duration(seconds: 15));

      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();
      expect(playPauseTapped, 1);
    });
  });

  group('FullPlayerPage', () {
    late MockPlayerCubit playerCubit;

    setUp(() {
      playerCubit = MockPlayerCubit();
      when(() => playerCubit.closeFullPlayer()).thenReturn(null);
      when(() => playerCubit.togglePlayPause()).thenAnswer((_) async {});
      when(() => playerCubit.seek(any())).thenAnswer((_) async {});
    });

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

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PlayerCubit>.value(
            value: playerCubit,
            child: const FullPlayerPage(),
          ),
        ),
      );

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

      await tester.pumpWidget(
        MaterialApp(
          home: BlocProvider<PlayerCubit>.value(
            value: playerCubit,
            child: const FullPlayerPage(),
          ),
        ),
      );

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.replay_10));
      await tester.pump();
      verify(() => playerCubit.seek(const Duration(seconds: 0))).called(1);

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

  group('TrackDeepLinkBridgePage', () {
    late MockTrackLoaderCubit loaderCubit;
    late MockPlayerCubit playerCubit;

    setUp(() {
      loaderCubit = MockTrackLoaderCubit();
      playerCubit = MockPlayerCubit();

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
      when(() => playerCubit.closeFullPlayer()).thenReturn(null);
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
