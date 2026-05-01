import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';

import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_state.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';

class MockPlayerCubit extends MockCubit<PlayerUIState> implements PlayerCubit {}

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockSubscriptionCubit extends MockCubit<Subscription?>
    implements SubscriptionCubit {}

class MockOfflineCubit extends MockCubit<OfflineState>
    implements OfflineCubit {}

void main() {
  final track = const Track(
    id: 't1',
    title: 'Track 1',
    artist: 'Artist 1',
    audioUrl: 'https://cdn/1.mp3',
  );

  final nextTrack = const Track(
    id: 't2',
    title: 'Track 2',
    artist: 'Artist 2',
    audioUrl: 'https://cdn/2.mp3',
  );

  late MockPlayerCubit playerCubit;
  late MockAudioPlayerService audioService;

  setUpAll(() {
    registerFallbackValue(track);
    registerFallbackValue(<Track>[]);
  });

  late MockSubscriptionCubit mockSubscriptionCubit;
  late MockOfflineCubit mockOfflineCubit;

  setUp(() async {
    await GetIt.I.reset();

    playerCubit = MockPlayerCubit();
    audioService = MockAudioPlayerService();

    mockSubscriptionCubit = MockSubscriptionCubit();
    mockOfflineCubit = MockOfflineCubit();

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

    when(() => playerCubit.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});

    when(() => audioService.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        )).thenAnswer((_) async {});

    // ✅ SubscriptionCubit mock
    when(() => mockSubscriptionCubit.state).thenReturn(
      const Subscription(
        subscriptionType: 'PRO',
        uploadLimit: 10,
        uploadedTracks: 0,
        remainingUploads: 10,
        canDownload: true,
        adsEnabled: false,
      ),
    );

    when(() => mockSubscriptionCubit.stream)
        .thenAnswer((_) => const Stream.empty());

    // ✅ OfflineCubit mock
    when(() => mockOfflineCubit.state).thenReturn(const OfflineState());

    when(() => mockOfflineCubit.stream).thenAnswer((_) => const Stream.empty());

    when(() => mockOfflineCubit.isDownloaded(any())).thenReturn(false);

    when(() => mockOfflineCubit.download(any())).thenAnswer((_) async {});
    when(() => mockOfflineCubit.downloadTrack(any())).thenAnswer((_) async {});
  });

  Widget buildSubject({List<Track>? queue}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: playerCubit),
        BlocProvider<SubscriptionCubit>.value(
          value: mockSubscriptionCubit,
        ),
        BlocProvider<OfflineCubit>.value(
          value: mockOfflineCubit,
        ),
      ],
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: Builder(
            builder: (context) {
              return TrackRow(
                track: track,
                queue: queue ?? [track],
                source: "test",
              );
            },
          ),
        ),
      ),
    );
  }

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
      PlayerUIState(
        playerState: const PlayerState(
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
    final queue = [nextTrack, track];

    await tester.pumpWidget(buildSubject(queue: queue));
    await tester.pump();

    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    verify(() => playerCubit.playFromContext(
          tracks: queue,
          startIndex: 1,
          source: "test",
        )).called(1);
  });
}
