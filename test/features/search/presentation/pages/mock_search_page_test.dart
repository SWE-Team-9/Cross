import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/search/presentation/pages/mock_search_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';

class MockAudioService extends Mock implements AudioPlayerService {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

/// ✅ FIX: Fake repo instead of throwing error
class FakeOfflineRepository implements OfflineRepository {
  final Map<String, String> _storage = {};
  final Map<String, Track> _trackDetails = {};
  final Map<String, PlaylistEntity> _playlists = {};

  @override
  late final DioClient dio;

  @override
  Future<String> downloadTrack(String trackId) async {
    final path = '/fake/$trackId.mp3';
    _storage[trackId] = path;
    return path;
  }

  @override
  Future<Track?> fetchTrackDetails(String trackId) async {
    return _trackDetails[trackId];
  }

  @override
  Future<Map<String, String>> getDownloadedTracks() async {
    return _storage;
  }

  @override
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    _storage
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    return _trackDetails;
  }

  @override
  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {
    _trackDetails
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    return _playlists;
  }

  @override
  Future<void> saveDownloadedPlaylists(Map<String, PlaylistEntity> data) async {
    _playlists
      ..clear()
      ..addAll(data);
  }
}

void main() {
  late MockAudioService audioService;
  late MockPlayerCubit playerCubit;

  setUpAll(() {
    registerFallbackValue(
      const Track(
        id: 'fallback',
        title: 'fallback',
        artist: 'fallback',
        audioUrl: 'fallback',
      ),
    );
    registerFallbackValue(<Track>[]);
  });

  setUp(() async {
    await GetIt.I.reset();

    audioService = MockAudioService();
    playerCubit = MockPlayerCubit();

    GetIt.I.registerSingleton<AudioPlayerService>(audioService);

    when(() => playerCubit.state).thenReturn(
      const PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );

    when(() => playerCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => audioService.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});

    when(() => playerCubit.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: playerCubit),

        /// ✅ FIXED
        BlocProvider<OfflineCubit>(
          create: (_) => OfflineCubit(FakeOfflineRepository()),
        ),

        BlocProvider(
          create: (_) => SubscriptionCubit(
            MockSubscriptionRepository(),
          )..loadSubscription(),
        ),
      ],
      child: MaterialApp.router(
        routerConfig: GoRouter(
          initialLocation: '/search',
          routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (context, state) => const MockSearchPage(),
            ),
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const Scaffold(
                body: Text('Home Route'),
              ),
            ),
            GoRoute(
              path: '/feed',
              name: 'feed',
              builder: (context, state) => const Scaffold(
                body: Text('Feed Route'),
              ),
            ),
            GoRoute(
              path: '/library',
              name: 'library',
              builder: (context, state) => const Scaffold(
                body: Text('Library Route'),
              ),
            ),
            GoRoute(
              path: '/upgrade',
              name: 'upgrade',
              builder: (context, state) => const Scaffold(
                body: Text('Upgrade Route'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  testWidgets('renders search page', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(MockSearchPage), findsOneWidget);
  });

  testWidgets('tap result triggers playback', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField), 'track');
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(InkWell, 'Feed Track 1'));
    await tester.pumpAndSettle();

    verify(() => playerCubit.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: "search",
        )).called(1);
  });
}
