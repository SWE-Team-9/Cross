import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/app/app.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/widgets/track_options_sheet.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_cubit.dart';
import 'package:soundcloud_clone/features/interactions/presentation/bloc/track_interaction_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_state.dart';

class MockPlaybackCubit extends MockCubit<PlaybackState>
    implements PlaybackCubit {}

class MockTrackInteractionCubit extends MockCubit<TrackInteractionState>
    implements TrackInteractionCubit {}

void main() {
  final track = const Track(
    id: 't1',
    title: 'Track 1',
    artist: 'Artist 1',
    audioUrl: 'https://cdn/1.mp3',
    likesCount: 3,
    repostsCount: 2,
  );

  late MockPlaybackCubit playbackCubit;
  late MockTrackInteractionCubit interactionCubit;

  Widget buildHost() {
    return MultiBlocProvider(
      providers: [
        BlocProvider<PlaybackCubit>.value(value: playbackCubit),
      ],
      child: MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () {
                    TrackOptionsSheet.show(context, track: track);
                  },
                  child: const Text('open'),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  setUpAll(() {
    registerFallbackValue(track);
  });

  setUp(() async {
    await getIt.reset();
    playbackCubit = MockPlaybackCubit();
    interactionCubit = MockTrackInteractionCubit();

    when(() => playbackCubit.state).thenReturn(const PlaybackState());
    when(() => playbackCubit.stream)
        .thenAnswer((_) => const Stream<PlaybackState>.empty());
    when(() => playbackCubit.addPlayNext(any())).thenReturn(null);
    when(() => playbackCubit.addPlayLast(any())).thenReturn(null);

    when(() => interactionCubit.state).thenReturn(
      TrackInteractionState.initial(),
    );
    when(() => interactionCubit.stream)
        .thenAnswer((_) => const Stream<TrackInteractionState>.empty());
    when(
      () => interactionCubit.load(
        trackId: any(named: 'trackId'),
        likesCount: any(named: 'likesCount'),
        repostsCount: any(named: 'repostsCount'),
      ),
    ).thenAnswer((_) async {});
    when(() => interactionCubit.toggleLike(any())).thenAnswer((_) async {});
    when(() => interactionCubit.toggleRepost(any())).thenAnswer((_) async {});

    getIt.registerFactory<TrackInteractionCubit>(() => interactionCubit);
    isTrackSheetOpen.value = false;
  });

  tearDown(() async {
    isTrackSheetOpen.value = false;
    await getIt.reset();
  });

  testWidgets('show renders track details and share items', (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(isTrackSheetOpen.value, isTrue);
    expect(find.text('Track 1'), findsOneWidget);
    expect(find.text('Artist 1'), findsOneWidget);
    expect(find.text('Message'), findsOneWidget);
    expect(find.text('Copy Link'), findsOneWidget);
    verify(
      () => interactionCubit.load(
        trackId: 't1',
        likesCount: 3,
        repostsCount: 2,
      ),
    ).called(1);
  });

  testWidgets('like and repost actions delegate to interaction cubit',
      (tester) async {
    await tester.pumpWidget(buildHost());
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Like'));
    await tester.pump();
    await tester.tap(find.text('Repost'));
    await tester.pump();

    verify(() => interactionCubit.toggleLike('t1')).called(1);
    verify(() => interactionCubit.toggleRepost('t1')).called(1);
  });

  testWidgets('play next and play last update playback queue and show snackbars',
      (tester) async {
    await tester.pumpWidget(buildHost());

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play Next'));
    await tester.pumpAndSettle();
    expect(find.text('"Track 1" will play next'), findsOneWidget);
    verify(() => playbackCubit.addPlayNext(track)).called(1);
    expect(isTrackSheetOpen.value, isFalse);

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Play Last'));
    await tester.pumpAndSettle();
    verify(() => playbackCubit.addPlayLast(track)).called(1);
  });
}
