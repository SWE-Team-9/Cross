import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';

class MockPlayerCubit extends MockCubit<PlayerUIState>
    implements PlayerCubit {}

class MockSubscriptionCubit extends MockCubit<SubscriptionState>
    implements SubscriptionCubit {}

class MockOfflineCubit extends MockCubit<OfflineState>
    implements OfflineCubit {}

void main() {
  const track = Track(
    id: 't1',
    title: 'Track 1',
    artist: 'Artist 1',
    audioUrl: 'https://cdn.example.com/1.mp3',
    artworkUrl: null,
  );

  const nextTrack = Track(
    id: 't2',
    title: 'Track 2',
    artist: 'Artist 2',
    audioUrl: 'https://cdn.example.com/2.mp3',
    artworkUrl: null,
  );

  const freeSubscriptionState = SubscriptionState(
    status: SubscriptionStatus.loaded,
    subscription: Subscription(
      planCode: 'FREE',
      subscriptionType: 'FREE',
      subscriptionStatus: 'ACTIVE',
      isPremium: false,
      canDownload: false,
      adsEnabled: true,
    ),
  );

  const premiumSubscriptionState = SubscriptionState(
    status: SubscriptionStatus.loaded,
    subscription: Subscription(
      planCode: 'PRO',
      subscriptionType: 'PRO',
      subscriptionStatus: 'ACTIVE',
      isPremium: true,
      canDownload: true,
      adsEnabled: false,
      uploadLimit: 100,
      uploadedTracks: 1,
      remainingUploads: 99,
    ),
  );

  late MockPlayerCubit playerCubit;
  late MockSubscriptionCubit subscriptionCubit;
  late MockOfflineCubit offlineCubit;

  setUpAll(() {
    registerFallbackValue(track);
    registerFallbackValue(<Track>[]);
  });

  setUp(() async {
    await GetIt.I.reset();

    playerCubit = MockPlayerCubit();
    subscriptionCubit = MockSubscriptionCubit();
    offlineCubit = MockOfflineCubit();

    when(() => playerCubit.state).thenReturn(
      const PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );

    when(() => playerCubit.stream).thenAnswer((_) => const Stream.empty());

    when(
      () => playerCubit.playFromContext(
        tracks: any(named: 'tracks'),
        startIndex: any(named: 'startIndex'),
        source: any(named: 'source'),
      ),
    ).thenAnswer((_) async {});

    when(() => subscriptionCubit.state).thenReturn(premiumSubscriptionState);
    when(() => subscriptionCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => offlineCubit.state).thenReturn(const OfflineState());
    when(() => offlineCubit.stream).thenAnswer((_) => const Stream.empty());
    when(() => offlineCubit.isDownloaded(any())).thenReturn(false);
    when(() => offlineCubit.getPath(any())).thenReturn(null);
    when(() => offlineCubit.downloadTrack(any())).thenAnswer((_) async {});
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Widget buildSubject({
    Track rowTrack = track,
    List<Track>? queue,
    bool includeSubscriptionCubit = true,
    bool includeOfflineCubit = true,
  }) {
    final providers = <BlocProvider>[
      BlocProvider<PlayerCubit>.value(value: playerCubit),
      if (includeSubscriptionCubit)
        BlocProvider<SubscriptionCubit>.value(value: subscriptionCubit),
      if (includeOfflineCubit) BlocProvider<OfflineCubit>.value(value: offlineCubit),
    ];

    return MultiBlocProvider(
      providers: providers,
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: TrackRow(
            track: rowTrack,
            queue: queue ?? <Track>[rowTrack],
            source: 'test-source',
          ),
        ),
      ),
    );
  }

  group('TrackRow', () {
    testWidgets('renders title and artist when track is not playing',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('Now Playing'), findsNothing);
    });

    testWidgets('shows now playing indicator for current playing track',
        (tester) async {
      when(() => playerCubit.state).thenReturn(
        const PlayerUIState(
          playerState: PlayerState(
            status: PlayerStatus.playing,
            position: Duration(seconds: 10),
            duration: Duration(seconds: 120),
          ),
          currentTrack: track,
        ),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.text('Now Playing'), findsOneWidget);
      expect(find.text('Artist 1'), findsNothing);
    });

    testWidgets('tap plays track using context queue', (tester) async {
      const queue = <Track>[nextTrack, track];

      await tester.pumpWidget(buildSubject(queue: queue));
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      verify(
        () => playerCubit.playFromContext(
          tracks: queue,
          startIndex: 1,
          source: 'test-source',
        ),
      ).called(1);
    });

    testWidgets('tap plays downloaded track with local path when available',
        (tester) async {
      when(() => offlineCubit.isDownloaded('t1')).thenReturn(true);
      when(() => offlineCubit.getPath('t1')).thenReturn('/offline/t1.mp3');

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byType(InkWell).first);
      await tester.pump();

      final verification = verify(
        () => playerCubit.playFromContext(
          tracks: captureAny(named: 'tracks'),
          startIndex: 0,
          source: 'test-source',
        ),
      )..called(1);

      final capturedTracks = verification.captured.single as List<Track>;

      expect(capturedTracks.single.id, 't1');
      expect(capturedTracks.single.localPath, '/offline/t1.mp3');
    });

    testWidgets('hides download action when subscription does not allow downloads',
        (tester) async {
      when(() => subscriptionCubit.state).thenReturn(freeSubscriptionState);

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
      expect(find.byIcon(Icons.download_done_rounded), findsNothing);
    });

    testWidgets('hides download action when premium cubits are unavailable',
        (tester) async {
      await tester.pumpWidget(
        buildSubject(
          includeSubscriptionCubit: false,
          includeOfflineCubit: false,
        ),
      );
      await tester.pump();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsNothing);
      expect(find.byIcon(Icons.download_done_rounded), findsNothing);
    });

    testWidgets('shows download action for premium downloadable tracks',
        (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byIcon(Icons.arrow_downward_rounded), findsOneWidget);
      expect(find.byIcon(Icons.download_done_rounded), findsNothing);
    });

    testWidgets('downloads track and shows saved snackbar', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
      await tester.pumpAndSettle();

      verify(() => offlineCubit.downloadTrack(track)).called(1);
      expect(find.text('Saved for offline listening'), findsOneWidget);
    });

    testWidgets('shows already downloaded state and snackbar', (tester) async {
      when(() => offlineCubit.isDownloaded('t1')).thenReturn(true);
      when(() => offlineCubit.getPath('t1')).thenReturn('/offline/t1.mp3');

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      expect(find.byIcon(Icons.download_done_rounded), findsOneWidget);

      await tester.tap(find.byIcon(Icons.download_done_rounded));
      await tester.pumpAndSettle();

      verifyNever(() => offlineCubit.downloadTrack(any()));
      expect(find.text('Music already downloaded'), findsOneWidget);
    });

    testWidgets('shows download failed snackbar for generic download error',
        (tester) async {
      when(() => offlineCubit.downloadTrack(any())).thenThrow(
        Exception('Network failed'),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Download failed'), findsOneWidget);
    });

    testWidgets('shows upgrade message when offline repository requires premium',
        (tester) async {
      when(() => offlineCubit.downloadTrack(any())).thenThrow(
        Exception('UPGRADE_REQUIRED'),
      );

      await tester.pumpWidget(buildSubject());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.arrow_downward_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade required for offline downloads'), findsWidgets);
    });

    testWidgets('falls back to default idle player state without player cubit',
        (tester) async {
      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<SubscriptionCubit>.value(value: subscriptionCubit),
            BlocProvider<OfflineCubit>.value(value: offlineCubit),
          ],
          child: const MaterialApp(
            home: Scaffold(
              backgroundColor: Colors.black,
              body: TrackRow(
                track: track,
                queue: <Track>[track],
                source: 'test-source',
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Track 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
      expect(find.text('Now Playing'), findsNothing);
    });
  });
}