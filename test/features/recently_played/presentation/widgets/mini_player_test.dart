import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/playback/presentation/widgets/mini_player.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';

class MockPlayerCubit extends Mock implements PlayerCubit {}

void main() {
  late MockPlayerCubit cubit;

  Widget buildTestWidget(Widget child) {
    return MaterialApp(
      home: BlocProvider<PlayerCubit>.value(
        value: cubit,
        child: Scaffold(body: child),
      ),
    );
  }

  setUp(() {
    cubit = MockPlayerCubit();
    when(() => cubit.stream).thenAnswer((_) => const Stream.empty());
    // MiniPlayer calls togglePlayPause() — stub it in setUp for all tests
    when(() => cubit.togglePlayPause()).thenAnswer((_) async {});
    when(() => cubit.openFullPlayer()).thenReturn(null);
  });

  testWidgets('MiniPlayer is hidden when no track', (tester) async {
    when(() => cubit.state).thenReturn(
      PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.idle,
          position: Duration.zero,
        ),
        currentTrack: null,
      ),
    );

    await tester.pumpWidget(buildTestWidget(const MiniPlayer()));

    expect(find.byType(MiniPlayer), findsOneWidget);
    expect(find.byType(SizedBox), findsOneWidget);
  });

  testWidgets('MiniPlayer shows track info when track exists', (tester) async {
    final track = Track(
      id: '1',
      title: 'Test Song',
      artist: 'Test Artist',
      audioUrl: 'url',
    );

    when(() => cubit.state).thenReturn(
      PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.playing,
          position: Duration.zero,
        ),
        currentTrack: track,
      ),
    );

    await tester.pumpWidget(buildTestWidget(const MiniPlayer()));

    expect(find.text('Test Song'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
  });

  testWidgets('Play button toggles playback', (tester) async {
    final track = Track(
      id: '1',
      title: 'Test Song',
      artist: 'Test Artist',
      audioUrl: 'url',
    );

    when(() => cubit.state).thenReturn(
      PlayerUIState(
        playerState: const PlayerState(
          status: PlayerStatus.paused,
          position: Duration.zero,
        ),
        currentTrack: track,
      ),
    );

    await tester.pumpWidget(buildTestWidget(const MiniPlayer()));

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    // MiniPlayer calls togglePlayPause() for both play and pause actions
    verify(() => cubit.togglePlayPause()).called(1);
  });
}