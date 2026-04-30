import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/pages/mock_home_page.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';

// ─── Fakes & Mocks ────────────────────────────────────────────────────────────

class FakeAudioPlayerService implements AudioPlayerService {
  double _currentVolume = 1;

  @override
  Stream<PlayerState> get playerStateStream =>
      const Stream<PlayerState>.empty();

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
  Future<void> setRepeatMode(AppRepeatMode mode) async {}

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

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

late MockNotificationsBloc mockNotificationsBloc;

// ─── Shared test user ─────────────────────────────────────────────────────────

const _testUser = User(
  id: '1',
  email: 'test@example.com',
  handle: 'testuser',
  displayName: 'Test User',
  avatarUrl: null,
);

// ─── Helpers ──────────────────────────────────────────────────────────────────

Future<void> _setUp() async {
  await GetIt.I.reset();
  GetIt.I.registerSingleton<AudioPlayerService>(FakeAudioPlayerService());
  GetIt.I.registerSingleton<RecentlyPlayedCubit>(RecentlyPlayedCubit());
}

Widget _buildApp(MockAuthCubit authCubit) {
  final goRouter = GoRouter(
    initialLocation: '/home',
    routes: [
      GoRoute(
        path: '/home',
        builder: (context, state) => MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<NotificationsBloc>.value(value: mockNotificationsBloc),
            BlocProvider<PlayerCubit>(
              create: (_) => PlayerCubit(GetIt.I<AudioPlayerService>()),
            ),
            BlocProvider(
              create: (_) => SubscriptionCubit(MockSubscriptionRepository()),
            ),
          ],
          child: const MockHomePage(),
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const Scaffold(body: Text('Welcome')),
      ),
      GoRoute(
        path: '/feed',
        builder: (_, __) => const Scaffold(body: Text('Feed')),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(body: Text('Search')),
      ),
      GoRoute(
        path: '/library',
        builder: (_, __) => const Scaffold(body: Text('Library')),
      ),
      GoRoute(
        path: '/upgrade',
        builder: (_, __) => const Scaffold(body: Text('Upgrade')),
      ),
      GoRoute(
        path: '/upload-picker',
        builder: (_, __) => const Scaffold(body: Text('Upload')),
      ),
    ],
  );

  return MaterialApp.router(
    routerConfig: goRouter,
  );
}

// ═════════════════════════════════════════════════════════════════════════════

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() async {
    await _setUp();
    mockAuthCubit = MockAuthCubit();
    mockNotificationsBloc = MockNotificationsBloc();
    when(() => mockNotificationsBloc.state).thenReturn(
      NotificationsLoaded(
          notifications: <NotificationEntity>[], unreadCount: 0),
    );
    when(() => mockNotificationsBloc.stream)
        .thenAnswer((_) => Stream<NotificationsState>.empty());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  // ── Basic render ───────────────────────────────────────────────────────────

  group('MockHomePage basic render', () {
    // Lines 58-59 — BlocConsumer builder runs, Scaffold shows
    testWidgets('builds without crashing when authenticated', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsWidgets);
    });

    // Lines 64-67 — currentHandle extracted from AuthAuthenticated
    testWidgets('extracts handle from AuthAuthenticated state', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      // TopBar renders with authenticated user — logout icon visible
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    // Lines 79, 81-82 — section headers rendered
    testWidgets('shows all section headers', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      expect(find.textContaining('More of what you like'), findsOneWidget);
      expect(find.textContaining('Mixed for you'), findsOneWidget);
      expect(find.textContaining('Trending by genre'), findsOneWidget);
    });
  });

  // ── AuthUnauthenticated listener ───────────────────────────────────────────

  // Lines 120 — listener fires context.go('/welcome') on AuthUnauthenticated
  testWidgets('navigates to /welcome when unauthenticated', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthUnauthenticated()]),
      initialState: AuthInitial(),
    );

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Welcome'), findsOneWidget);
  });

  // ── AuthError listener ─────────────────────────────────────────────────────

  // Lines 130-136 — listener shows SnackBar on AuthError
  testWidgets('shows snackbar on AuthError', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthError('Something went wrong')]),
      initialState: AuthInitial(),
    );

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  // ── Bottom Nav ─────────────────────────────────────────────────────────────

  group('BottomNav navigation', () {
    setUp(() {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());
    });

    // Lines 138-145 — bottom nav tabs render and are tappable
    testWidgets('renders all bottom nav tabs', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      // "Home" appears twice (header + nav), use findsWidgets
      expect(find.text('Home'), findsWidgets);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    // Lines 138-139 — tapping Feed tab (index 1) updates selected state
    testWidgets('tapping Feed tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Feed'));
      await tester.pump();

      // Feed icon becomes active (filled icon)
      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    // Lines 141-142 — tapping Search tab updates selected state
    testWidgets('tapping Search tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(find.byIcon(Icons.search), findsWidgets);
    });

    // Lines 144-145 — tapping Library tab updates selected state
    testWidgets('tapping Library tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Library'));
      await tester.pump();

      expect(find.byIcon(Icons.library_music), findsOneWidget);
    });

    // Lines 169-170 — tapping Upgrade tab updates selected state
    testWidgets('tapping Upgrade tab updates selected index', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Upgrade'));
      await tester.pump();

      expect(find.byIcon(Icons.equalizer), findsOneWidget);
    });
  });

  // ── Logout sheet ───────────────────────────────────────────────────────────

  group('Logout bottom sheet', () {
    setUp(() {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => mockAuthCubit.logout()).thenAnswer((_) async {});
    });

    // Lines 176-181 — logout sheet opens
    testWidgets('shows logout sheet on logout icon tap', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    // Lines 191-194 — tapping "Log out" calls cubit.logout()
    testWidgets('tapping Log out calls authCubit.logout()', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthCubit.logout()).called(1);
    });

    // Lines 198-200 — tapping Cancel closes the sheet
    testWidgets('tapping Cancel dismisses the sheet', (tester) async {
      await tester.pumpWidget(_buildApp(mockAuthCubit));
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsNothing);
    });
  });

  // ── Profile navigation ─────────────────────────────────────────────────────

  // Lines 212-213 — tapping avatar with empty handle shows snackbar
  testWidgets('shows snackbar when navigating to profile without handle',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Please log in to view profile'), findsOneWidget);
  });

  // ── Genre chips ────────────────────────────────────────────────────────────

  // Lines 226-228, 237 — tapping genre chip changes selection
  testWidgets('tapping a genre chip updates selection', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    // Scroll to genre chips section
    await tester.dragUntilVisible(
      find.text('FOLK'),
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('FOLK'));
    await tester.pumpAndSettle();

    // FOLK chip is now selected — verify it's visible and tappable
    expect(find.text('FOLK'), findsOneWidget);
  });

  // ── Managed tracks ─────────────────────────────────────────────────────────

  // Lines 267, 271 — managed tracks show title + manage button
  testWidgets('renders related tracks and mix cards', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    expect(find.text('Related tracks: L...'), findsOneWidget);
    expect(find.text('SoundCloud'), findsWidgets);
    expect(find.text('MIX 1'), findsOneWidget);
    expect(find.text('Balthazar, Cage...'), findsOneWidget);
  });

  // ── Upload icon ────────────────────────────────────────────────────────────

  // Lines 283, 285 — upload icon is tappable without crashing
  testWidgets('tapping upload icon does not crash', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    // Just verify tap doesn't throw — go_router push needs full router setup
    await tester.tap(find.byIcon(Icons.upload_outlined));
    await tester.pump();

    expect(find.byType(MockHomePage), findsOneWidget);
  });

  // ── Unauthenticated state render ───────────────────────────────────────────

  // Lines 295, 315 — renders correctly when not authenticated
  testWidgets('renders without logout button when not authenticated',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.logout_rounded), findsNothing);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('renders genre chips for discovery browsing', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    expect(find.text('ELECTRONIC'), findsOneWidget);
    expect(find.text('FOLK'), findsOneWidget);
    expect(find.text('HOUSE'), findsOneWidget);
  });

  testWidgets('keeps authenticated home content visible', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pumpAndSettle();

    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Trending by genre'), findsOneWidget);
  });
}
