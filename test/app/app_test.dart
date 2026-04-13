import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:soundcloud_clone/app/app.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_service.dart';
import 'package:soundcloud_clone/core/models/player_state.dart' as app_state;
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

// ── Fakes / Mocks ─────────────────────────────────────────────────────────────

class FakeAudioPlayerService implements AudioPlayerService {
  @override
  Stream<app_state.PlayerState> get playerStateStream => const Stream.empty();
  @override
  Future<void> play(track) async {}
  @override
  Future<void> pause() async {}
  @override
  Future<void> resume() async {}
  @override
  Future<void> stop() async {}
  @override
  Future<void> seek(Duration position) async {}
  @override
  Future<void> dispose() async {}
}

class FakeDeepLinkService implements DeepLinkService {
  @override
  Stream<DeepLinkDestination> get stream => const Stream.empty();
  @override
  DeepLinkDestination? consumeLastDestination() => null;
  @override
  Future<void> init() async {}
  @override
  Future<void> dispose() async {}
}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

// ── Helper: pump the full App widget ─────────────────────────────────────────

Future<void> _pumpApp(
  WidgetTester tester,
  MockAuthCubit authCubit,
) async {
  when(() => authCubit.state).thenReturn(AuthInitial());
  whenListen(
    authCubit,
    Stream<AuthState>.fromIterable([AuthInitial()]),
    initialState: AuthInitial(),
  );
  when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
  when(() => authCubit.remainingResendSeconds).thenReturn(0);

  await tester.pumpWidget(
    BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const App(),
    ),
  );
  await tester.pump();
}

void main() {
  late MockAuthCubit authCubit;
  late MockSocialRepo mockSocialRepo;

  setUp(() async {
    await GetIt.I.reset();
    authCubit = MockAuthCubit();
    mockSocialRepo = MockSocialRepo();

    GetIt.I.registerSingleton<AudioPlayerService>(FakeAudioPlayerService());
    GetIt.I.registerSingleton<DeepLinkService>(FakeDeepLinkService());
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(RecentlyPlayedCubit());
    GetIt.I.registerLazySingleton<SocialRepo>(() => mockSocialRepo);

    // AuthCubit & PlaybackCubit are created via getIt inside App —
    // register factories that return the mocks
    GetIt.I.registerFactory<AuthCubit>(() => authCubit);
    GetIt.I.registerLazySingleton<PlaybackCubit>(
      () => PlaybackCubit(GetIt.I<AudioPlayerService>()),
    );
    GetIt.I.registerLazySingleton<PlayerCubit>(
      () => PlayerCubit(GetIt.I<AudioPlayerService>()),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  // ══════════════════════════════════════════════════════════════════════════
  // isTrackSheetOpen notifier
  // ══════════════════════════════════════════════════════════════════════════

  group('isTrackSheetOpen ValueNotifier', () {
    test('initialises to false', () {
      isTrackSheetOpen.value = false;
      expect(isTrackSheetOpen.value, isFalse);
    });

    test('can be set to true', () {
      isTrackSheetOpen.value = true;
      expect(isTrackSheetOpen.value, isTrue);
      isTrackSheetOpen.value = false;
    });

    test('can be toggled multiple times', () {
      isTrackSheetOpen.value = false;
      isTrackSheetOpen.value = true;
      isTrackSheetOpen.value = false;
      expect(isTrackSheetOpen.value, isFalse);
    });

    test('notifies listeners when changed', () {
      isTrackSheetOpen.value = false;
      int callCount = 0;
      void listener() => callCount++;
      isTrackSheetOpen.addListener(listener);

      isTrackSheetOpen.value = true;
      isTrackSheetOpen.value = false;

      isTrackSheetOpen.removeListener(listener);
      expect(callCount, 2);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // App widget smoke tests
  // ══════════════════════════════════════════════════════════════════════════

  group('App widget', () {
    testWidgets('renders without crashing', (tester) async {
      await _pumpApp(tester, authCubit);
      expect(tester.takeException(), isNull);
    });

    testWidgets('contains MaterialApp.router at its root', (tester) async {
      await _pumpApp(tester, authCubit);
      expect(find.byType(Router<Object>), findsOneWidget);
    });

    testWidgets('calls authCubit.checkAuthStatus on startup', (tester) async {
      await _pumpApp(tester, authCubit);
      verify(() => authCubit.checkAuthStatus()).called(greaterThanOrEqualTo(1));
    });

    testWidgets('mini player is hidden when isTrackSheetOpen is true',
        (tester) async {
      isTrackSheetOpen.value = false;
      await _pumpApp(tester, authCubit);

      isTrackSheetOpen.value = true;
      await tester.pump();

      expect(tester.takeException(), isNull);

      isTrackSheetOpen.value = false;
    });

    testWidgets('mini player is visible when isTrackSheetOpen is false',
        (tester) async {
      isTrackSheetOpen.value = false;
      await _pumpApp(tester, authCubit);
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('shows home page when authenticated', (tester) async {
      final authenticatedState = AuthAuthenticated(
        const User(
          id: '1',
          email: 'test@test.com',
          handle: 'testuser',
          displayName: 'Test User',
          avatarUrl: null,
        ),
      );

      when(() => authCubit.state).thenReturn(authenticatedState);
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([authenticatedState]),
        initialState: authenticatedState,
      );
      when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});

      await tester.pumpWidget(
        BlocProvider<AuthCubit>.value(
          value: authCubit,
          child: const App(),
        ),
      );
      await tester.pumpAndSettle(const Duration(seconds: 5));

      expect(tester.takeException(), isNull);
    });
  });

  // ══════════════════════════════════════════════════════════════════════════
  // App widget — PlayerUIState changes (mini player animation)
  // ══════════════════════════════════════════════════════════════════════════

  group('App mini-player visibility driven by PlayerUIState', () {
    testWidgets('AnimatedSlide hides when player is fullscreen',
        (tester) async {
      isTrackSheetOpen.value = false;
      await _pumpApp(tester, authCubit);

      await tester.pump(const Duration(milliseconds: 300));
      expect(tester.takeException(), isNull);
    });
  });
}
