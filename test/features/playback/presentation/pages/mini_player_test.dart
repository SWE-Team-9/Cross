import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/core/models/player_state.dart' as app_player;
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_ui_state.dart';
import 'package:soundcloud_clone/features/playback/presentation/widgets/mini_player.dart';

// ── Fake state for fallback registration ──────────────────────────────────────

class FakePlayerUIState extends Fake implements PlayerUIState {}

// ── Fixtures ──────────────────────────────────────────────────────────────────

const _track = Track(
  id: 'tr1',
  title: 'Test Track',
  artist: 'Test Artist',
  audioUrl: 'https://example.com/audio.mp3',
  artworkUrl: null,
  handle: null,
);

PlayerUIState _idle() => PlayerUIState(
      playerState: const app_player.PlayerState(
        status: app_player.PlayerStatus.idle,
        position: Duration.zero,
      ),
    );

PlayerUIState _withTrack({required bool isPlaying}) => PlayerUIState(
      playerState: app_player.PlayerState(
        status: isPlaying
            ? app_player.PlayerStatus.playing
            : app_player.PlayerStatus.paused,
        position: Duration.zero,
      ),
      currentTrack: _track,
    );

// ── Stub cubit ────────────────────────────────────────────────────────────────
//
// We can't use MockCubit<S> (from bloc_test) because it mixes Mock + Cubit
// and Dart doesn't allow multiple superclasses.
// Instead we hand-roll a minimal stub that exposes the stream/state pair
// that BlocBuilder needs, and records calls to togglePlayPause / openFullPlayer.

class _StubPlayerCubit extends Cubit<PlayerUIState> implements PlayerCubit {
  _StubPlayerCubit(super.initialState);

  bool toggleCalled = false;
  bool openFullPlayerCalled = false;

  @override
  Future<void> togglePlayPause() async => toggleCalled = true;

  @override
  void openFullPlayer() => openFullPlayerCalled = true;

  // ── Unused PlayerCubit members — satisfy the interface ────────────────────

  @override
  Future<void> play(Track track) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> stop() async {}

  @override
  void closeFullPlayer() {}
  @override
  void hideMiniPlayer() {}

  @override
  void showMiniPlayer() {}
}

// ── Tests ─────────────────────────────────────────────────────────────────────

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakePlayerUIState());
  });

  /// Pumps [MiniPlayer] driven by a stub cubit pre-loaded with [state].
  Future<_StubPlayerCubit> pump(
    WidgetTester tester,
    PlayerUIState state,
  ) async {
    final cubit = _StubPlayerCubit(state);

    await tester.pumpWidget(
      BlocProvider<PlayerCubit>.value(
        value: cubit,
        child: const MaterialApp(
          home: Scaffold(body: MiniPlayer()),
        ),
      ),
    );
    await tester.pump();
    return cubit;
  }

  // ── Tests ──────────────────────────────────────────────────────────────────

  testWidgets('renders nothing when no track is loaded', (tester) async {
    await pump(tester, _idle());

    expect(find.byIcon(Icons.pause), findsNothing);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('displays track title and artist when track is loaded',
      (tester) async {
    await pump(tester, _withTrack(isPlaying: false));

    expect(find.text('Test Track'), findsOneWidget);
    expect(find.text('Test Artist'), findsOneWidget);
  });

  testWidgets('Play button toggles playback — calls pause when playing',
      (tester) async {
    final cubit = await pump(tester, _withTrack(isPlaying: true));

    expect(find.byIcon(Icons.pause), findsOneWidget);

    await tester.tap(find.byIcon(Icons.pause));
    await tester.pump();

    expect(cubit.toggleCalled, isTrue);
  });

  testWidgets('Play button calls resume when paused', (tester) async {
    final cubit = await pump(tester, _withTrack(isPlaying: false));

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow));
    await tester.pump();

    expect(cubit.toggleCalled, isTrue);
  });

  testWidgets('shows pause icon when playing', (tester) async {
    await pump(tester, _withTrack(isPlaying: true));

    expect(find.byIcon(Icons.pause), findsOneWidget);
    expect(find.byIcon(Icons.play_arrow), findsNothing);
  });

  testWidgets('shows play icon when paused', (tester) async {
    await pump(tester, _withTrack(isPlaying: false));

    expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    expect(find.byIcon(Icons.pause), findsNothing);
  });
}
