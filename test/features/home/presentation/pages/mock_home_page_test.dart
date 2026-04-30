import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/pages/mock_home_page.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
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

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

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

  final getUnreadCountUseCase = MockGetUnreadCountUseCase();
  final connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();

  when(() => getUnreadCountUseCase()).thenAnswer(
    (_) async => const UnreadCountEntity(count: 0),
  );

  when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});

  when(() => connectMessagingSocketUseCase.eventsStream).thenAnswer(
    (_) => const Stream<RealtimeMessageEventEntity>.empty(),
  );

  GetIt.I.registerSingleton<AudioPlayerService>(FakeAudioPlayerService());
  GetIt.I.registerSingleton<RecentlyPlayedCubit>(RecentlyPlayedCubit());

  GetIt.I.registerFactory<UnreadCountCubit>(
    () => UnreadCountCubit(
      getUnreadCountUseCase: getUnreadCountUseCase,
      connectMessagingSocketUseCase: connectMessagingSocketUseCase,
    ),
  );
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

Future<void> _pumpHome(
  WidgetTester tester,
  MockAuthCubit authCubit,
) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(_buildApp(authCubit));
  await tester.pumpAndSettle();
}

// ═════════════════════════════════════════════════════════════════════════════

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() async {
    await _setUp();
    mockAuthCubit = MockAuthCubit();
  });

  tearDown(() async {
    testerViewReset();
    await GetIt.I.reset();
  });

  // ── Basic render ───────────────────────────────────────────────────────────

  group('MockHomePage basic render', () {
    testWidgets('builds without crashing when authenticated', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await _pumpHome(tester, mockAuthCubit);

      expect(find.byType(Scaffold), findsWidgets);
    });

    testWidgets('extracts handle from AuthAuthenticated state', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await _pumpHome(tester, mockAuthCubit);

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('shows all section headers', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await _pumpHome(tester, mockAuthCubit);

      expect(find.textContaining('More of what you like'), findsOneWidget);
      expect(find.textContaining('Mixed for you'), findsOneWidget);
      expect(find.textContaining('Trending by genre'), findsOneWidget);
    });
  });

  testWidgets('navigates to /welcome when unauthenticated', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthUnauthenticated()]),
      initialState: AuthInitial(),
    );

    await _pumpHome(tester, mockAuthCubit);

    expect(find.text('Welcome'), findsOneWidget);
  });

  testWidgets('shows snackbar on AuthError', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    whenListen(
      mockAuthCubit,
      Stream<AuthState>.fromIterable([AuthError('Something went wrong')]),
      initialState: AuthInitial(),
    );

    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    await tester.pumpWidget(_buildApp(mockAuthCubit));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Something went wrong'), findsOneWidget);
  });

  group('BottomNav navigation', () {
    setUp(() {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());
    });

    testWidgets('renders all bottom nav tabs', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(find.text('Upgrade'), findsOneWidget);
    });

    testWidgets('tapping Feed tab updates selected index', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Feed'));
      await tester.pump();

      expect(find.byIcon(Icons.grid_view), findsOneWidget);
    });

    testWidgets('tapping Search tab updates selected index', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Search'));
      await tester.pump();

      expect(find.byIcon(Icons.search), findsWidgets);
    });

    testWidgets('tapping Library tab updates selected index', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Library'));
      await tester.pump();

      expect(find.byIcon(Icons.library_music), findsOneWidget);
    });

    testWidgets('tapping Upgrade tab updates selected index', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Upgrade'));
      await tester.pump();

      expect(find.byIcon(Icons.equalizer), findsOneWidget);
    });
  });

  group('Logout bottom sheet', () {
    setUp(() {
      when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
      when(() => mockAuthCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());
      when(() => mockAuthCubit.logout()).thenAnswer((_) async {});
    });

    testWidgets('shows logout sheet on logout icon tap', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsOneWidget);
      expect(find.text('Log out'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('tapping Log out calls authCubit.logout()', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Log out'));
      await tester.pumpAndSettle();

      verify(() => mockAuthCubit.logout()).called(1);
    });

    testWidgets('tapping Cancel dismisses the sheet', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.byIcon(Icons.logout_rounded));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Log out of Iqa3?'), findsNothing);
    });
  });

  testWidgets('shows snackbar when navigating to profile without handle',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    await tester.tap(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.text('Please log in to view profile'), findsOneWidget);
  });

  testWidgets('tapping a genre chip updates selection', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    await tester.dragUntilVisible(
      find.text('folk-singer-songwriter'),
      find.byType(SingleChildScrollView),
      const Offset(0, -100),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('folk-singer-songwriter'));
    await tester.pumpAndSettle();

    expect(find.text('folk-singer-songwriter'), findsOneWidget);
  });

  testWidgets('renders related tracks and mix cards', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    expect(find.text('Related tracks: L...'), findsOneWidget);
    expect(find.text('SoundCloud'), findsWidgets);
    expect(find.text('MIX 1'), findsOneWidget);
    expect(find.text('Balthazar, Cage...'), findsOneWidget);
  });

  testWidgets('tapping upload icon does not crash', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    await tester.tap(find.byIcon(Icons.upload_outlined));
    await tester.pump();

    expect(find.byType(MockHomePage), findsOneWidget);
  });

  testWidgets('renders without logout button when not authenticated',
      (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthInitial());
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    expect(find.byIcon(Icons.logout_rounded), findsNothing);
    expect(find.byType(CircleAvatar), findsOneWidget);
  });

  testWidgets('renders genre chips for discovery browsing', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    expect(find.text('electronic'), findsOneWidget);
    expect(find.text('hip-hop'), findsOneWidget);
    expect(find.text('house'), findsOneWidget);
  });

  testWidgets('keeps authenticated home content visible', (tester) async {
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    await _pumpHome(tester, mockAuthCubit);

    expect(find.text('Home'), findsWidgets);
    expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    expect(find.text('Trending by genre'), findsOneWidget);
  });
}

void testerViewReset() {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.views.first.resetPhysicalSize();
  binding.platformDispatcher.views.first.resetDevicePixelRatio();
}
