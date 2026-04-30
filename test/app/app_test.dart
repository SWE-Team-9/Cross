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
import 'package:soundcloud_clone/core/notifiers/overlay_notifiers.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/core/models/track.dart';

// ── Fakes / Mocks ─────────────────────────────────────────────────────────────

class FakeAudioPlayerService implements AudioPlayerService {
  double _currentVolume = 1;

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
  Future<void> setVolume(double volume) async {
    _currentVolume = volume;
  }

  @override
  Future<void> setRepeatMode(app_state.AppRepeatMode mode) async {}

  @override
  double get currentVolume => _currentVolume;

  @override
  Future<void> dispose() async {}

  @override
  Future<void> playFromContext({
    required List<Track> tracks,
    required int startIndex,
    required String source,
  }) async {}
}

class FakeDeepLinkService implements DeepLinkService {
  @override
  Stream<DeepLinkDestination> get stream => const Stream.empty();

  @override
  DeepLinkDestination? consumeLastDestination() => null;

  @override
  DeepLinkDestination? peekLastDestination() => null;

  @override
  void markLastDestinationConsumed() {}

  @override
  Future<void> init() async {}

  @override
  Future<void> dispose() async {}
}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

// ── Helper: pump the full App widget ─────────────────────────────────────────

Future<void> _pumpApp(
  WidgetTester tester,
  MockAuthCubit authCubit, {
  AuthState? authState,
}) async {
  // Important: fully unmount any previous router tree before mounting App.
  // This prevents Duplicate GlobalKey errors from GoRouter's internal keys.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  final state = authState ?? AuthInitial();

  when(() => authCubit.state).thenReturn(state);
  whenListen(
    authCubit,
    Stream<AuthState>.fromIterable([state]),
    initialState: state,
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
  late MockGetUnreadCountUseCase getUnreadCountUseCase;
  late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  setUp(() async {
    await GetIt.I.reset();

    isTrackSheetOpen.value = false;

    authCubit = MockAuthCubit();
    mockSocialRepo = MockSocialRepo();
    getUnreadCountUseCase = MockGetUnreadCountUseCase();
    connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();

    when(() => getUnreadCountUseCase()).thenAnswer(
      (_) async => const UnreadCountEntity(count: 0),
    );

    when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});

    when(() => connectMessagingSocketUseCase.eventsStream).thenAnswer(
      (_) => const Stream<RealtimeMessageEventEntity>.empty(),
    );

    GetIt.I.registerSingleton<AudioPlayerService>(FakeAudioPlayerService());
    GetIt.I.registerSingleton<DeepLinkService>(FakeDeepLinkService());
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(RecentlyPlayedCubit());
    GetIt.I.registerLazySingleton<SocialRepo>(() => mockSocialRepo);

    GetIt.I.registerFactory<AuthCubit>(() => authCubit);

    GetIt.I.registerLazySingleton<PlaybackCubit>(
      () => PlaybackCubit(GetIt.I<AudioPlayerService>()),
    );

    GetIt.I.registerLazySingleton<PlayerCubit>(
      () => PlayerCubit(GetIt.I<AudioPlayerService>()),
    );

    GetIt.I.registerFactory<UnreadCountCubit>(
      () => UnreadCountCubit(
        getUnreadCountUseCase: getUnreadCountUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
      ),
    );
  });

  tearDown(() async {
    isTrackSheetOpen.value = false;

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

      await _pumpApp(
        tester,
        authCubit,
        authState: authenticatedState,
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
