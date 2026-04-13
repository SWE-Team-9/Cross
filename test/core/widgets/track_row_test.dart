import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_row.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_state.dart';

class MockPlayerCubit extends MockCubit<PlayerUIState> implements PlayerCubit {}

class MockPlaybackCubit extends MockCubit<PlaybackState>
    implements PlaybackCubit {}

void main() {
  final track = const Track(
    id: 't1',
    title: 'Track 1',
    artist: 'Artist 1',
    audioUrl: 'https://cdn/1.mp3',
    handle: 'artist1',
  );
  final nextTrack = const Track(
    id: 't2',
    title: 'Track 2',
    artist: 'Artist 2',
    audioUrl: 'https://cdn/2.mp3',
    handle: 'artist2',
  );

  late MockPlayerCubit playerCubit;
  late MockPlaybackCubit playbackCubit;

  setUpAll(() {
    registerFallbackValue(
      const Track(
          id: 'fallback',
          title: 'fallback',
          artist: 'fallback',
          audioUrl: 'fallback'),
    );
    registerFallbackValue(<Track>[]);
  });

  Widget buildSubject({List<Track>? queue}) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlayerCubit>.value(value: playerCubit),
        BlocProvider<PlaybackCubit>.value(value: playbackCubit),
      ],
      child: MaterialApp(
        home: Scaffold(
          backgroundColor: Colors.black,
          body: TrackRow(track: track, queue: queue),
        ),
      ),
    );
  }

  setUp(() {
    playerCubit = MockPlayerCubit();
    playbackCubit = MockPlaybackCubit();

    when(() => playerCubit.state).thenReturn(
      const PlayerUIState(
        playerState: PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
      ),
    );
    when(() => playerCubit.stream)
        .thenAnswer((_) => const Stream<PlayerUIState>.empty());
    when(() => playerCubit.play(any())).thenAnswer((_) async {});

    when(() => playbackCubit.state).thenReturn(const PlaybackState());
    when(() => playbackCubit.stream)
        .thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => playbackCubit.playTrack(any(), any())).thenAnswer((_) async {});
  });

  testWidgets('renders title and artist when track is not playing',
      (tester) async {
    await tester.pumpWidget(buildSubject());

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

    expect(find.text('Now Playing'), findsOneWidget);
    expect(find.text('Artist 1'), findsNothing);
  });

  testWidgets('tap plays track and remaining queue from current index',
      (tester) async {
    final queue = [nextTrack, track];

    await tester.pumpWidget(buildSubject(queue: queue));
    await tester.tap(find.byType(InkWell).first);
    await tester.pump();

    verify(() => playbackCubit.playTrack(track, [track])).called(1);
    verify(() => playerCubit.play(track)).called(1);
  });
}
