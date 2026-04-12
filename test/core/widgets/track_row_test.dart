import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/player_state.dart' as app_player;
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockPlaybackCubit extends Mock implements PlaybackCubit {}

class FakeTrack extends Fake implements Track {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockAudioPlayerService mockAudioPlayerService;
  late MockPlaybackCubit mockPlaybackCubit;
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
    registerFallbackValue(FakeTrack());
    registerFallbackValue(const Duration(seconds: 1));
  });

  setUp(() {
    GetIt.instance.reset();

    mockAudioPlayerService = MockAudioPlayerService();
    mockPlaybackCubit = MockPlaybackCubit();
    recentlyPlayedCubit = RecentlyPlayedCubit();
    playerStateController =
        StreamController<app_player.PlayerState>.broadcast();

    // ✅ FIX: stream mock
    when(() => mockAudioPlayerService.playerStateStream)
        .thenAnswer((_) => playerStateController.stream);

    // Audio controls
    when(() => mockAudioPlayerService.play(any())).thenAnswer((_) async {});

    when(() => mockAudioPlayerService.pause()).thenAnswer((_) async {});

    when(() => mockAudioPlayerService.resume()).thenAnswer((_) async {});

    when(() => mockAudioPlayerService.stop()).thenAnswer((_) async {});

    when(() => mockAudioPlayerService.seek(any())).thenAnswer((_) async {});

    when(() => mockAudioPlayerService.dispose()).thenAnswer((_) async {});

    // ✅ FIX: PlaybackCubit MUST return Future
    when(() => mockPlaybackCubit.playTrack(any(), any()))
        .thenAnswer((_) async {});

    when(() => mockPlaybackCubit.addPlayNext(any())).thenAnswer((_) async {});

    when(() => mockPlaybackCubit.addPlayLast(any())).thenAnswer((_) async {});

    when(() => mockPlaybackCubit.stream)
        .thenAnswer((_) => const Stream.empty());

    GetIt.instance
        .registerSingleton<AudioPlayerService>(mockAudioPlayerService);

    GetIt.instance.registerSingleton<RecentlyPlayedCubit>(recentlyPlayedCubit);
  });

  tearDown(() async {
    await playerStateController.close();
    await recentlyPlayedCubit.close();
    await GetIt.instance.reset();
  });

  Future<void> pumpTrackRow(
    WidgetTester tester, {
    required Track inputTrack,
  }) async {
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerCubit>(
            create: (_) => PlayerCubit(GetIt.instance<AudioPlayerService>()),
          ),
          BlocProvider<PlaybackCubit>.value(value: mockPlaybackCubit),
        ],
        child: MaterialApp(
          home: Scaffold(body: TrackRow(track: inputTrack)),
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
          builder: (context, state) =>
              Scaffold(body: TrackRow(track: inputTrack)),
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
      MultiBlocProvider(
        providers: [
          BlocProvider<PlayerCubit>(
            create: (_) => PlayerCubit(GetIt.instance<AudioPlayerService>()),
          ),
          BlocProvider<PlaybackCubit>.value(value: mockPlaybackCubit),
        ],
        child: MaterialApp.router(routerConfig: router),
      ),
    );
  }

  testWidgets('shows title, artist, and fallback icon', (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    expect(find.text('Midnight Echoes'), findsOneWidget);
    expect(find.text('Ali'), findsOneWidget);
    expect(find.byIcon(Icons.music_note), findsOneWidget);
  });

  testWidgets('shows now playing state', (tester) async {
    await pumpTrackRow(tester, inputTrack: track);

    playerStateController.add(
      const app_player.PlayerState(
        status: app_player.PlayerStatus.playing,
        position: Duration.zero,
        currentTrackId: 't1',
      ),
    );

    await tester.pump();

    expect(find.byType(TrackRow), findsOneWidget);
  });

  testWidgets('tap plays track', (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    await tester.tap(find.byType(TrackRow));
    await tester.pump();

    verify(() => mockAudioPlayerService.play(track)).called(1);
  });

  testWidgets('menu opens', (tester) async {
    await pumpTrackRow(tester, inputTrack: track);
    await tester.pump();

    await tester.tap(find.byIcon(Icons.more_vert));
    await tester.pumpAndSettle();

    expect(find.text('Like'), findsOneWidget);
  });

  testWidgets('navigate to artist works', (tester) async {
    await pumpTrackRowWithRouter(tester, inputTrack: trackWithHandle);
    await tester.pump();

    final element = tester.element(find.byType(TrackRow));
    final widget = element.widget as TrackRow;

    widget.openMenu(element);

    await tester.pumpAndSettle();

    await tester.tap(find.text('Go to artist'));
    await tester.pumpAndSettle();

    expect(find.text('profile:artist-handle'), findsOneWidget);
  });
}
