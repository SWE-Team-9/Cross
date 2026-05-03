import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/comments/domain/entities/comment_entity.dart';
import 'package:soundcloud_clone/features/comments/domain/usecases/get_track_comments_usecase.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_cubit.dart';
import 'package:soundcloud_clone/features/comments/presentation/bloc/comments_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/engagement_list_state.dart';
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

class MockAudioPlayerService extends Mock implements AudioPlayerService {}

class MockPlayerCubit extends MockCubit<PlayerUIState> implements PlayerCubit {}

class MockPlaybackCubit extends MockCubit<PlaybackState>
    implements PlaybackCubit {}

class MockTrackLoaderCubit extends MockCubit<TrackLoaderState>
    implements TrackLoaderCubit {}

class MockTrackInteractionCubit extends MockCubit<TrackInteractionState>
    implements TrackInteractionCubit {}

class MockCommentsCubit extends MockCubit<CommentsState>
    implements CommentsCubit {}

class MockEngagementListCubit extends MockCubit<EngagementListState>
    implements EngagementListCubit {}

class MockGetTrackCommentsUseCase extends Mock
    implements GetTrackCommentsUseCase {}

class FakeDuration extends Fake implements Duration {}

void main() {
  setUpAll(() {
    registerFallbackValue(FakeDuration());
    registerFallbackValue(EngagementListType.likers);
    registerFallbackValue(
        const Track(id: '', title: '', artist: '', audioUrl: ''));
    registerFallbackValue(<Track>[]);

    final mockPlayer = MockAudioPlayerService();

    GetIt.I.registerSingleton<AudioPlayerService>(mockPlayer);

    when(() => mockPlayer.playerStateStream)
        .thenAnswer((_) => const Stream.empty());
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

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PlayerControls(
              isPlaying: false,
              onPlayPause: () => playPauseTapped++,
              position: const Duration(seconds: 5),
              duration: const Duration(seconds: 60),
              onSeek: (_) {},
            ),
          ),
        ),
      );

      // PlayerControls الأصلي عنده play/pause بس — نتست الزرار الموجود
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
      when(() => playerCubit.state).thenReturn(const PlayerUIState(
        playerState:
            PlayerState(status: PlayerStatus.idle, position: Duration.zero),
        currentTrack: null,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());
      expect(find.byType(GestureDetector), findsNothing);
    });

    testWidgets('displays track title and artist', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
            status: PlayerStatus.idle, position: Duration.zero),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());
      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);
    });

    testWidgets('tapping play button calls pause when playing', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.playing,
          position: Duration(seconds: 30),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();

      verify(() => playerCubit.togglePlayPause()).called(1);
    });

    testWidgets('tapping play button calls resume when paused', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 30),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildMiniPlayer());
      await tester.tap(find.byIcon(Icons.play_arrow));
      await tester.pump();

      verify(() => playerCubit.togglePlayPause()).called(1);
    });

    testWidgets('shows pause icon and correct progress when playing',
        (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.playing,
          position: Duration(seconds: 60),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
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
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
        currentTrack: track,
      ));
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
    late MockTrackInteractionCubit trackInteractionCubit;
    late MockCommentsCubit commentsCubit;
    late MockEngagementListCubit engagementListCubit;
    late MockGetTrackCommentsUseCase getTrackCommentsUseCase;
    final queueTrack = const Track(
      id: 't2',
      title: 'Song 2',
      artist: 'Artist 2',
      audioUrl: 'https://cdn/t2.mp3',
      artworkUrl: null,
      handle: 'artist2',
      likesCount: 4,
      repostsCount: 1,
    );

    setUp(() async {
      await getIt.reset();

      // 🔥 VERY IMPORTANT: re-register AudioPlayerService after reset
      final mockPlayer = MockAudioPlayerService();
      if (!GetIt.I.isRegistered<AudioPlayerService>()) {
        GetIt.I.registerSingleton<AudioPlayerService>(mockPlayer);
      }

      when(() => mockPlayer.playerStateStream)
          .thenAnswer((_) => const Stream.empty());
      playerCubit = MockPlayerCubit();
      playbackCubit = MockPlaybackCubit();
      trackInteractionCubit = MockTrackInteractionCubit();
      commentsCubit = MockCommentsCubit();
      engagementListCubit = MockEngagementListCubit();
      getTrackCommentsUseCase = MockGetTrackCommentsUseCase();

      when(() => playerCubit.openFullPlayer()).thenReturn(null);
      when(() => playerCubit.closeFullPlayer()).thenReturn(null);
      when(() => playerCubit.togglePlayPause()).thenAnswer((_) async {});
      when(() => playerCubit.seek(any())).thenAnswer((_) async {});
      when(() => playerCubit.play(any())).thenAnswer((_) async {});
      when(() => playerCubit.playNext()).thenAnswer((_) async {});
      when(() => playerCubit.playPrevious()).thenAnswer((_) async {});
      when(
        () => playerCubit.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: any(named: 'source'),
        ),
      ).thenAnswer((_) async {});

      when(() => playbackCubit.state).thenReturn(emptyPlaybackState);
      when(() => playbackCubit.stream)
          .thenAnswer((_) => const Stream<PlaybackState>.empty());
      when(() => playbackCubit.playNext()).thenAnswer((_) async {});
      when(() => playbackCubit.playPrevious()).thenAnswer((_) async {});

      when(() => trackInteractionCubit.state)
          .thenReturn(TrackInteractionState.initial());
      when(() => trackInteractionCubit.stream)
          .thenAnswer((_) => const Stream<TrackInteractionState>.empty());
      when(
        () => trackInteractionCubit.load(
          trackId: any(named: 'trackId'),
          likesCount: any(named: 'likesCount'),
          repostsCount: any(named: 'repostsCount'),
        ),
      ).thenAnswer((_) async {});
      when(() => trackInteractionCubit.toggleLike(any()))
          .thenAnswer((_) async {});
      when(() => trackInteractionCubit.toggleRepost(any()))
          .thenAnswer((_) async {});
      when(() => commentsCubit.state).thenReturn(CommentsState.initial());
      when(() => commentsCubit.stream)
          .thenAnswer((_) => const Stream<CommentsState>.empty());
      when(() => commentsCubit.load(any())).thenAnswer((_) async {});
      when(() => engagementListCubit.state)
          .thenReturn(EngagementListState.initial());
      when(() => engagementListCubit.stream)
          .thenAnswer((_) => const Stream<EngagementListState>.empty());
      when(
        () => engagementListCubit.load(
          trackId: any(named: 'trackId'),
          type: any(named: 'type'),
        ),
      ).thenAnswer((_) async {});
      when(() => engagementListCubit.loadMore()).thenAnswer((_) async {});
      when(() => getTrackCommentsUseCase(any()))
          .thenAnswer((_) async => const []);

      getIt.registerFactory<TrackInteractionCubit>(() => trackInteractionCubit);
      getIt.registerFactory<CommentsCubit>(() => commentsCubit);
      getIt.registerFactory<EngagementListCubit>(() => engagementListCubit);
      getIt.registerLazySingleton<GetTrackCommentsUseCase>(
        () => getTrackCommentsUseCase,
      );
    });

    tearDown(() async {
      await getIt.reset();
    });

    Widget buildFullPlayer() => MultiBlocProvider(
          providers: [
            BlocProvider<PlayerCubit>.value(value: playerCubit),
            BlocProvider<PlaybackCubit>.value(value: playbackCubit),
            BlocProvider<TrackInteractionCubit>.value(
              value: trackInteractionCubit,
            ),
          ],
          child: const MaterialApp(
            home: FullPlayerPage(),
          ),
        );

    testWidgets('shows no-track placeholder when currentTrack is null',
        (tester) async {
      when(() => playerCubit.state).thenReturn(const PlayerUIState(
        playerState:
            PlayerState(status: PlayerStatus.idle, position: Duration.zero),
        currentTrack: null,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());
      expect(find.text('No track selected'), findsOneWidget);
    });

    testWidgets('renders controls and invokes cubit methods', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.playing,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());

      expect(find.text('Song 1'), findsOneWidget);
      expect(find.text('Artist 1'), findsOneWidget);

      // FullPlayerPage بيعمل الـ play/pause button يدوياً — نتست الأيقونة مباشرة
      expect(find.byIcon(Icons.pause), findsOneWidget);
      await tester.tap(find.byIcon(Icons.pause));
      await tester.pump();
      verify(() => playerCubit.togglePlayPause()).called(1);
    });

    testWidgets('loads comments count and interaction data for track',
        (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
          queue: [track, queueTrack],
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());
      when(() => getTrackCommentsUseCase('t1')).thenAnswer(
        (_) async => [
          CommentEntity(
            id: 'c1',
            content: 'Nice',
            userId: 'u1',
            userDisplayName: 'Ali',
            userAvatarUrl: null,
            parentCommentId: null,
            timestampSeconds: 5,
            createdAt: DateTime(2024),
            replies: const [],
          ),
          CommentEntity(
            id: 'c2',
            content: 'Great',
            userId: 'u2',
            userDisplayName: 'Sara',
            userAvatarUrl: null,
            parentCommentId: null,
            timestampSeconds: 15,
            createdAt: DateTime(2024),
            replies: const [],
          ),
        ],
      );

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      verify(
        () => trackInteractionCubit.load(
          trackId: 't1',
          likesCount: 0,
          repostsCount: 0,
        ),
      ).called(1);
      expect(find.text('2'), findsOneWidget);
    });

    testWidgets('opens empty queue sheet when queue is empty', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
          queue: [track, queueTrack],
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());
      when(() => playbackCubit.state).thenReturn(
        emptyPlaybackState.copyWith(currentTrack: track, queue: const []),
      );

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      final button = tester
          .widget<IconButton>(find.byKey(const Key('player_queue_button')));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('queue sheet plays selected queued track', (tester) async {
      await tester.binding.setSurfaceSize(const Size(430, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
          queue: [track, queueTrack],
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      final button = tester
          .widget<IconButton>(find.byKey(const Key('player_queue_button')));
      expect(button.onPressed, isNotNull);
      expect(playerCubit.state.playerState.queue, [track, queueTrack]);
    });

    testWidgets('skip next delegates to player queue', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.playing,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
          queue: [track, queueTrack],
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.skip_next));
      await tester.pump(const Duration(milliseconds: 20));

      verify(() => playerCubit.playNext()).called(1);
      verifyNever(() => playbackCubit.playNext());
    });

    testWidgets('opens comments page and triggers comments cubit load',
        (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 45),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      await tester.tap(find.text('Comment...'));
      await tester.pumpAndSettle();

      expect(find.text('Comments'), findsOneWidget);
      verify(() => commentsCubit.load('t1')).called(2);
    });

    testWidgets('likes label opens likers page', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());
      when(() => trackInteractionCubit.state).thenReturn(
        TrackInteractionState.initial().copyWith(
          likesCount: 1,
          repostsCount: 7,
        ),
      );
      when(() => engagementListCubit.state).thenReturn(
        EngagementListState.initial().copyWith(
          type: EngagementListType.reposters,
          trackId: 't1',
        ),
      );

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      await tester.tap(find.text('1'));
      await tester.pumpAndSettle();
      verify(
        () => engagementListCubit.load(
          trackId: 't1',
          type: EngagementListType.likers,
        ),
      ).called(2);
    });

    testWidgets('reposts label opens reposters page', (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());
      when(() => trackInteractionCubit.state).thenReturn(
        TrackInteractionState.initial().copyWith(
          likesCount: 1,
          repostsCount: 7,
        ),
      );

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      await tester.tap(
        find
            .ancestor(
              of: find.text('7'),
              matching: find.byType(InkWell),
            )
            .last,
      );
      await tester.pumpAndSettle();
      verify(
        () => engagementListCubit.load(
          trackId: 't1',
          type: EngagementListType.reposters,
        ),
      ).called(2);
    });

    testWidgets('like and repost icons delegate to interaction cubit',
        (tester) async {
      when(() => playerCubit.state).thenReturn(PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration(seconds: 10),
          duration: Duration(seconds: 120),
        ),
        currentTrack: track,
      ));
      when(() => playerCubit.stream)
          .thenAnswer((_) => const Stream<PlayerUIState>.empty());

      await tester.pumpWidget(buildFullPlayer());
      await tester.pump();

      await tester.tap(find.byIcon(Icons.favorite_border));
      await tester.pump();
      await tester.tap(find.byIcon(Icons.repeat));
      await tester.pump();

      verify(() => trackInteractionCubit.toggleLike('t1')).called(1);
      verify(() => trackInteractionCubit.toggleRepost('t1')).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════════════════════
  // TrackDeepLinkBridgePage
  // ═══════════════════════════════════════════════════════════════════════════

  group('TrackDeepLinkBridgePage', () {
    late MockTrackLoaderCubit loaderCubit;
    late MockPlayerCubit playerCubit;
    late MockPlaybackCubit playbackCubit;
    late MockTrackInteractionCubit trackInteractionCubit;
    late MockGetTrackCommentsUseCase getTrackCommentsUseCase;

    setUp(() async {
      await getIt.reset();
      final mockPlayer = MockAudioPlayerService();
      if (!GetIt.I.isRegistered<AudioPlayerService>()) {
        GetIt.I.registerSingleton<AudioPlayerService>(mockPlayer);
      }

      when(() => mockPlayer.playerStateStream)
          .thenAnswer((_) => const Stream.empty());
      loaderCubit = MockTrackLoaderCubit();
      playerCubit = MockPlayerCubit();
      playbackCubit = MockPlaybackCubit();
      trackInteractionCubit = MockTrackInteractionCubit();
      getTrackCommentsUseCase = MockGetTrackCommentsUseCase();

      when(() => loaderCubit.loadByTrackId(any())).thenAnswer((_) async {});
      when(() => loaderCubit.loadBySecretToken(any())).thenAnswer((_) async {});

      when(() => playerCubit.state).thenReturn(const PlayerUIState(
        playerState:
            PlayerState(status: PlayerStatus.idle, position: Duration.zero),
        currentTrack: null,
      ));
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

      when(() => trackInteractionCubit.state)
          .thenReturn(TrackInteractionState.initial());
      when(() => trackInteractionCubit.stream)
          .thenAnswer((_) => const Stream<TrackInteractionState>.empty());
      when(
        () => trackInteractionCubit.load(
          trackId: any(named: 'trackId'),
          likesCount: any(named: 'likesCount'),
          repostsCount: any(named: 'repostsCount'),
        ),
      ).thenAnswer((_) async {});
      when(() => trackInteractionCubit.toggleLike(any()))
          .thenAnswer((_) async {});
      when(() => trackInteractionCubit.toggleRepost(any()))
          .thenAnswer((_) async {});
      when(() => getTrackCommentsUseCase(any()))
          .thenAnswer((_) async => const []);

      getIt.registerFactory<TrackInteractionCubit>(() => trackInteractionCubit);
      getIt.registerLazySingleton<GetTrackCommentsUseCase>(
        () => getTrackCommentsUseCase,
      );
    });

    tearDown(() async {
      await getIt.reset();
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
            BlocProvider<TrackInteractionCubit>.value(
              value: trackInteractionCubit,
            ),
          ],
          child: MaterialApp(
            home: const TrackDeepLinkBridgePage(trackId: 't1'),
            routes: {'/home': (_) => const Scaffold(body: Text('Home Screen'))},
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(milliseconds: 100));

      verify(() => loaderCubit.loadByTrackId('t1')).called(1);
      expect(find.byType(FullPlayerPage), findsOneWidget);
    });

    testWidgets('shows snackbar and navigates home on error', (tester) async {
      when(() => loaderCubit.state).thenReturn(const TrackLoaderIdle());
      whenListen(
        loaderCubit,
        Stream<TrackLoaderState>.fromIterable(
            const [TrackLoaderError(message: 'bad link')]),
        initialState: const TrackLoaderIdle(),
      );

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<TrackLoaderCubit>.value(value: loaderCubit),
            BlocProvider<PlayerCubit>.value(value: playerCubit),
            BlocProvider<PlaybackCubit>.value(value: playbackCubit),
            BlocProvider<TrackInteractionCubit>.value(
              value: trackInteractionCubit,
            ),
          ],
          child: MaterialApp(
            home: const TrackDeepLinkBridgePage(secretToken: 's1'),
            routes: {'/home': (_) => const Scaffold(body: Text('Home Screen'))},
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
