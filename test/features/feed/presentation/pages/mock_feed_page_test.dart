import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mocktail/mocktail.dart';
import 'package:get_it/get_it.dart';

import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/feed/presentation/pages/mock_feed_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';

class MockAudioService extends Mock implements AudioPlayerService {}

class MockPlayerCubit extends Mock implements PlayerCubit {}

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

    when(() => playerCubit.play(any())).thenAnswer((_) async {});
  });

  Widget buildSubject() {
    return BlocProvider<PlayerCubit>.value(
      value: playerCubit,
      child: MaterialApp(
        home: Builder(
          builder: (context) => const MockFeedPage(),
        ),
      ),
    );
  }

  testWidgets('renders feed page', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    expect(find.byType(MockFeedPage), findsOneWidget);
  });

  testWidgets('tap on track triggers playback', (tester) async {
    await tester.pumpWidget(buildSubject());
    await tester.pumpAndSettle();

    await tester.tap(find.byType(GestureDetector).first);
    await tester.pumpAndSettle();

    verify(() => audioService.playFromContext(
          tracks: any(named: 'tracks'),
          startIndex: any(named: 'startIndex'),
          source: "feed",
        )).called(1);

    verify(() => playerCubit.play(any())).called(1);
  });
}
