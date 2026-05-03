import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/library/presentation/pages/downloaded_items_page.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';

class MockOfflineCubit extends MockCubit<OfflineState>
    implements OfflineCubit {}

class MockSubscriptionCubit extends MockCubit<SubscriptionState>
    implements SubscriptionCubit {}

void main() {
  const downloadedTrack = Track(
    id: 'track-1',
    title: 'Offline Track',
    artist: 'Offline Artist',
    audioUrl: '',
    localPath: '/offline/track-1.mp3',
  );

  const premiumState = SubscriptionState(
    status: SubscriptionStatus.loaded,
    subscription: Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      planName: 'Pro',
      isPremium: true,
      canDownload: true,
      adsEnabled: false,
      uploadLimit: 100,
      uploadedTracks: 2,
      remainingUploads: 98,
    ),
  );

  const freeState = SubscriptionState(
    status: SubscriptionStatus.loaded,
    subscription: Subscription(
      planCode: 'FREE',
      subscriptionType: 'FREE',
      subscriptionStatus: 'ACTIVE',
      planName: 'Free',
      isPremium: false,
      canDownload: false,
      adsEnabled: true,
      uploadLimit: 3,
      uploadedTracks: 1,
      remainingUploads: 2,
    ),
  );

  late MockOfflineCubit offlineCubit;
  late MockSubscriptionCubit subscriptionCubit;

  setUpAll(() {
    registerFallbackValue(downloadedTrack);
  });

  setUp(() async {
    await GetIt.I.reset();

    offlineCubit = MockOfflineCubit();
    subscriptionCubit = MockSubscriptionCubit();

    when(() => offlineCubit.state).thenReturn(const OfflineState());
    when(() => offlineCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => offlineCubit.isDownloaded(any())).thenReturn(false);
    when(() => offlineCubit.getPath(any())).thenReturn(null);
    when(() => offlineCubit.downloadTrack(any())).thenAnswer((_) async {});

    when(() => subscriptionCubit.state).thenReturn(premiumState);
    when(() => subscriptionCubit.stream).thenAnswer(
      (_) => const Stream<SubscriptionState>.empty(),
    );

    GetIt.I.registerSingleton<OfflineCubit>(offlineCubit);
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  group('DownloadedTracksPage premium gate', () {
    testWidgets('shows loading indicator while subscription is loading',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(
        const SubscriptionState(status: SubscriptionStatus.loading),
      );

      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('No downloaded tracks yet'), findsNothing);
    });

    testWidgets('locks downloaded tracks for free users', (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Downloaded tracks'), findsOneWidget);
      expect(find.text('Offline downloads are premium'), findsOneWidget);
      expect(
        find.text(
            'Upgrade to save tracks and playlists for offline listening.'),
        findsOneWidget,
      );
      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('No downloaded tracks yet'), findsNothing);
    });

    testWidgets('upgrade button navigates to upgrade route for locked tracks',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: subscriptionCubit,
      );

      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Route'), findsOneWidget);
    });

    testWidgets('shows empty downloaded tracks state for premium users',
        (tester) async {
      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Downloaded tracks'), findsOneWidget);
      expect(find.text('No downloaded tracks yet'), findsOneWidget);
      expect(find.text('Offline downloads are premium'), findsNothing);
    });

    testWidgets('renders downloaded track details for premium users',
        (tester) async {
      when(() => offlineCubit.state).thenReturn(
        const OfflineState(
          downloadedTrackDetails: <String, Track>{
            'track-1': downloadedTrack,
          },
        ),
      );
      when(() => offlineCubit.isDownloaded('track-1')).thenReturn(true);
      when(() => offlineCubit.getPath('track-1')).thenReturn(
        '/offline/track-1.mp3',
      );

      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Offline Track'), findsOneWidget);
      expect(find.text('Offline Artist'), findsOneWidget);
      expect(find.text('No downloaded tracks yet'), findsNothing);
    });

    testWidgets('renders fallback track when only local path map exists',
        (tester) async {
      when(() => offlineCubit.state).thenReturn(
        const OfflineState(
          downloadedTracks: <String, String>{
            'track-1': '/offline/track-1.mp3',
          },
        ),
      );
      when(() => offlineCubit.isDownloaded('track-1')).thenReturn(true);
      when(() => offlineCubit.getPath('track-1')).thenReturn(
        '/offline/track-1.mp3',
      );

      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('track-1'), findsOneWidget);
      expect(find.text('Downloaded track'), findsOneWidget);
    });

    testWidgets(
        'falls back to downloaded tracks content without subscription cubit',
        (tester) async {
      when(() => offlineCubit.state).thenReturn(
        const OfflineState(
          downloadedTrackDetails: <String, Track>{
            'track-1': downloadedTrack,
          },
        ),
      );

      await _pumpDownloadedPage(
        tester,
        const DownloadedTracksPage(),
        subscriptionCubit: null,
      );

      expect(find.text('Offline Track'), findsOneWidget);
      expect(find.text('Offline downloads are premium'), findsNothing);
    });
  });

  group('DownloadedPlaylistsPage premium gate', () {
    testWidgets('locks downloaded playlists for free users', (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpDownloadedPage(
        tester,
        const DownloadedPlaylistsPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Downloaded playlists'), findsOneWidget);
      expect(find.text('Offline downloads are premium'), findsOneWidget);
      expect(find.text('No downloaded playlists yet'), findsNothing);
    });

    testWidgets(
        'upgrade button navigates to upgrade route for locked playlists',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeState);

      await _pumpDownloadedPage(
        tester,
        const DownloadedPlaylistsPage(),
        subscriptionCubit: subscriptionCubit,
      );

      await tester.tap(find.text('Upgrade'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Route'), findsOneWidget);
    });

    testWidgets('shows empty downloaded playlists state for premium users',
        (tester) async {
      await _pumpDownloadedPage(
        tester,
        const DownloadedPlaylistsPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Downloaded playlists'), findsOneWidget);
      expect(find.text('No downloaded playlists yet'), findsOneWidget);
      expect(find.text('Offline downloads are premium'), findsNothing);
    });

    testWidgets('renders downloaded playlists for premium users',
        (tester) async {
      when(() => offlineCubit.state).thenReturn(
        OfflineState(
          downloadedPlaylists: <String, PlaylistEntity>{
            'playlist-1': _playlist(
              tracks: const <Track>[downloadedTrack],
            ),
          },
        ),
      );

      await _pumpDownloadedPage(
        tester,
        const DownloadedPlaylistsPage(),
        subscriptionCubit: subscriptionCubit,
      );

      expect(find.text('Offline Mix'), findsOneWidget);
      expect(find.text('1 downloaded tracks'), findsOneWidget);
      expect(find.text('No downloaded playlists yet'), findsNothing);
    });

    testWidgets('tapping downloaded playlist opens playlist route',
        (tester) async {
      when(() => offlineCubit.state).thenReturn(
        OfflineState(
          downloadedPlaylists: <String, PlaylistEntity>{
            'playlist-1': _playlist(),
          },
        ),
      );

      await _pumpDownloadedPage(
        tester,
        const DownloadedPlaylistsPage(),
        subscriptionCubit: subscriptionCubit,
      );

      await tester.tap(find.text('Offline Mix'));
      await tester.pumpAndSettle();

      expect(find.text('Playlist Route playlist-1'), findsOneWidget);
    });
  });
}

Future<void> _pumpDownloadedPage(
  WidgetTester tester,
  Widget page, {
  required MockSubscriptionCubit? subscriptionCubit,
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;

  addTearDown(() {
    tester.view.resetPhysicalSize();
    tester.view.resetDevicePixelRatio();
  });

  final router = GoRouter(
    initialLocation: '/downloads',
    routes: [
      GoRoute(
        path: '/downloads',
        builder: (context, state) {
          if (subscriptionCubit == null) {
            return page;
          }

          return BlocProvider<SubscriptionCubit>.value(
            value: subscriptionCubit,
            child: page,
          );
        },
      ),
      GoRoute(
        path: '/upgrade',
        builder: (context, state) {
          return const Scaffold(
            body: Center(
              child: Text('Upgrade Route'),
            ),
          );
        },
      ),
      GoRoute(
        path: '/playlist/:playlistId',
        builder: (context, state) {
          final playlistId = state.pathParameters['playlistId'] ?? '';

          return Scaffold(
            body: Center(
              child: Text('Playlist Route $playlistId'),
            ),
          );
        },
      ),
    ],
  );

  await tester.pumpWidget(
    MaterialApp.router(
      routerConfig: router,
    ),
  );

  await tester.pump();
  await tester.pump();
}

PlaylistEntity _playlist({
  String playlistId = 'playlist-1',
  List<Track> tracks = const <Track>[],
}) {
  return PlaylistEntity(
    playlistId: playlistId,
    title: 'Offline Mix',
    description: 'Saved playlist',
    visibility: PlaylistVisibility.publicPlaylist,
    genre: 'Electronic',
    genreId: 7,
    slug: 'offline-mix',
    playlistType: 'PLAYLIST',
    releaseDate: DateTime.parse('2026-04-01T00:00:00.000Z'),
    tags: const <String>['electronic', 'mix'],
    secretToken: 'secret-token',
    coverImageUrl: '',
    owner: const PlaylistOwner(
      id: 'owner-1',
      displayName: 'DJ Nova',
    ),
    tracks: tracks,
    tracksCount: tracks.length,
    likesCount: 10,
    isLiked: true,
  );
}
