import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/player_state.dart' as app_player;
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late GetIt getIt;
  late MockAudioPlayerService mockAudioPlayerService;
  late RecentlyPlayedCubit recentlyPlayedCubit;
  late StreamController<app_player.PlayerState> playerStateController;

  const track = Track(
    id: 't1',
    title: 'Midnight Echoes',
    artist: 'Ali',
    audioUrl: 'https://example.com/audio.mp3',
    artworkUrl: null,
    handle: null,
  );

  const trackWithHandle = Track(
    id: 't2',
    title: 'City Lights',
    artist: 'Omar',
    audioUrl: 'https://example.com/audio2.mp3',
    artworkUrl: null,
    handle: 'artist-handle',
  );

  setUpAll(() {
    registerFallbackValue(track);
    registerFallbackValue(
      const Track(
        id: 'fallback',
        title: 'Fallback',
        artist: 'Fallback',
        audioUrl: 'https://example.com/fallback.mp3',
      ),
    );
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    getIt = GetIt.instance;
    getIt.reset();

    mockAudioPlayerService = MockAudioPlayerService();
    recentlyPlayedCubit = RecentlyPlayedCubit();
    playerStateController =
        StreamController<app_player.PlayerState>.broadcast();

    when(() => mockAudioPlayerService.playerStateStream)
        .thenAnswer((_) => playerStateController.stream);
    when(() => mockAudioPlayerService.play(any())).thenAnswer((_) async {});
    when(() => mockAudioPlayerService.pause()).thenAnswer((_) async {});
    when(() => mockAudioPlayerService.stop()).thenAnswer((_) async {});
    when(() => mockAudioPlayerService.seek(any())).thenAnswer((_) async {});
    when(() => mockAudioPlayerService.dispose()).thenAnswer((_) async {});

    getIt.registerSingleton<AudioPlayerService>(mockAudioPlayerService);
    getIt.registerSingleton<RecentlyPlayedCubit>(recentlyPlayedCubit);
  });

  tearDown(() async {
    await playerStateController.close();
    await recentlyPlayedCubit.close();
    await getIt.reset();
  });

  Future<void> pumpTrackRow(
    WidgetTester tester, {
    required Track inputTrack,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TrackRow(track: inputTrack),
        ),
      ),
    );
  }

  Future<void> pumpTrackRowWithRouter(
    WidgetTester tester, {
    required Track inputTrack,
  }) async {
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: TrackRow(track: inputTrack),
          ),
        ),
        GoRoute(
          path: '/profile/:handle',
          builder: (context, state) => Scaffold(
            body: Text('profile:${state.pathParameters['handle']}'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('shows title, artist, and fallback music icon when no artwork',
      (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    expect(find.text('Midnight Echoes'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
    expect(find.text('Now Playing'), findsNothing);
  });

  testWidgets('shows now playing state when current track id matches',
      (tester) async {
    await pumpTrackRow(tester, inputTrack: track);

    playerStateController.add(
      const app_player.PlayerState(
        status: app_player.PlayerStatus.playing,
        position: Duration.zero,
        currentTrackId: 't1',
      ),
    );

    await tester.pump();

    expect(find.text('Now Playing'), findsOneWidget);
    expect(find.byIcon(Icons.equalizer), findsOneWidget);
    expect(find.text('Ali'), findsNothing);
  });

  testWidgets('tap row plays track and adds it to recently played',
      (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    expect(recentlyPlayedCubit.state, isEmpty);

    await tester.tap(find.text('Midnight Echoes'));
    await tester.pump();

    verify(() => mockAudioPlayerService.play(track)).called(1);
    expect(recentlyPlayedCubit.state.length, 1);
    expect(recentlyPlayedCubit.state.first.id, 't1');
  });

  testWidgets('more button opens bottom sheet menu', (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Like'), findsOneWidget);
    expect(find.text('Add to playlist'), findsOneWidget);
    expect(find.text('Go to artist'), findsOneWidget);
    expect(find.text('Report'), findsOneWidget);
  });

  testWidgets('Go to artist shows snackbar when handle is missing',
      (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to artist'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Artist profile not available'), findsOneWidget);
  });

  testWidgets('Go to artist navigates when handle exists', (tester) async {
    await pumpTrackRowWithRouter(tester, inputTrack: trackWithHandle);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Go to artist'), findsOneWidget);

    await tester.tap(find.text('Go to artist'));
    await tester.pumpAndSettle();

    expect(find.text('profile:artist-handle'), findsOneWidget);
  });
}
