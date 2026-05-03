import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/domain/entities/notification_entity.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/core/widgets/bottom_nav_bar.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/pages/mock_home_page.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_invoice.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/billing_portal_session.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/offline_track_entitlement.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/plan.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/profile/domain/entities/profile_entity.dart';
import 'package:soundcloud_clone/features/profile/domain/repositories/profile_repository.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/upload/domain/entities/managed_track.dart';

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
  Future<void> playLocalFile(String path) async {}

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

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

class MockProfileRepository extends Mock implements ProfileRepository {}

const _testUser = User(
  id: '1',
  email: 'test@example.com',
  handle: 'testuser',
  displayName: 'Test User',
  avatarUrl: null,
);

late AudioPlayerService audioService;
late OfflineCubit offlineCubit;

Future<void> _setUp() async {
  await GetIt.I.reset();

  final getUnreadCountUseCase = MockGetUnreadCountUseCase();
  final connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
  final profileRepository = MockProfileRepository();

  audioService = FakeAudioPlayerService();
  offlineCubit = OfflineCubit(_FakeOfflineRepository());

  when(() => getUnreadCountUseCase()).thenAnswer(
    (_) async => const UnreadCountEntity(count: 0),
  );

  when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});

  when(() => connectMessagingSocketUseCase.eventsStream).thenAnswer(
    (_) => const Stream<RealtimeMessageEventEntity>.empty(),
  );

  when(() => profileRepository.getMyProfile()).thenAnswer(
    (_) async => const ProfileEntity(
      id: 'profile_1',
      displayName: 'Test User',
      handle: 'testuser',
      accountTier: AccountTier.LISTENER,
      favoriteGenres: <String>['electronic', 'hip-hop', 'pop'],
      externalLinks: <String, String>{},
      visibility: ProfileVisibility.PUBLIC,
      followersCount: 0,
      followingCount: 0,
    ),
  );

  when(() => profileRepository.getProfile(any())).thenAnswer(
    (_) async => const ProfileEntity(
      id: 'profile_1',
      displayName: 'Test User',
      handle: 'testuser',
      accountTier: AccountTier.LISTENER,
      favoriteGenres: <String>['electronic', 'hip-hop', 'pop'],
      externalLinks: <String, String>{},
      visibility: ProfileVisibility.PUBLIC,
      followersCount: 0,
      followingCount: 0,
    ),
  );

  when(() => profileRepository.getUserTracks(any())).thenAnswer(
    (_) async => const <ManagedTrack>[],
  );

  GetIt.I.registerSingleton<AudioPlayerService>(audioService);
  GetIt.I.registerSingleton<ProfileRepository>(profileRepository);
  GetIt.I.registerSingleton<RecentlyPlayedCubit>(RecentlyPlayedCubit());
  GetIt.I.registerSingleton<OfflineCubit>(offlineCubit);

  GetIt.I.registerFactory<UnreadCountCubit>(
    () => UnreadCountCubit(
      getUnreadCountUseCase: getUnreadCountUseCase,
      connectMessagingSocketUseCase: connectMessagingSocketUseCase,
    ),
  );
}

Widget _buildApp(
  MockAuthCubit authCubit, {
  Subscription subscription = const Subscription(
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'ACTIVE',
    planName: 'Free',
    isPremium: false,
    canDownload: false,
    adsEnabled: true,
  ),
}) {
  final subscriptionRepository = _FakeSubscriptionRepository(
    subscription: subscription,
  );

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
            BlocProvider<SubscriptionCubit>(
              create: (_) =>
                  SubscriptionCubit(subscriptionRepository)..loadSubscription(),
            ),
          ],
          child: const MockHomePage(),
        ),
      ),
      GoRoute(
        path: '/welcome',
        builder: (_, __) => const Scaffold(body: Text('Welcome Route')),
      ),
      GoRoute(
        path: '/feed',
        builder: (_, __) => const Scaffold(body: Text('Feed Route')),
      ),
      GoRoute(
        path: '/search',
        builder: (_, __) => const Scaffold(body: Text('Search Route')),
      ),
      GoRoute(
        path: '/library',
        builder: (_, __) => const Scaffold(body: Text('Library Route')),
      ),
      GoRoute(
        path: '/upgrade',
        builder: (_, __) => const Scaffold(body: Text('Upgrade Route')),
      ),
      GoRoute(
        path: '/upload-picker',
        builder: (_, __) => const Scaffold(body: Text('Upload Route')),
      ),
    ],
  );

  return MaterialApp.router(routerConfig: goRouter);
}

Future<void> _pumpHome(
  WidgetTester tester,
  MockAuthCubit authCubit, {
  Subscription subscription = const Subscription(
    planCode: 'FREE',
    subscriptionType: 'FREE',
    subscriptionStatus: 'ACTIVE',
    planName: 'Free',
    isPremium: false,
    canDownload: false,
    adsEnabled: true,
  ),
}) async {
  tester.view.physicalSize = const Size(1200, 1800);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    _buildApp(
      authCubit,
      subscription: subscription,
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  late MockAuthCubit mockAuthCubit;

  setUp(() async {
    await _setUp();

    mockAuthCubit = MockAuthCubit();
    when(() => mockAuthCubit.state).thenReturn(AuthAuthenticated(_testUser));
    when(() => mockAuthCubit.stream).thenAnswer(
      (_) => const Stream<AuthState>.empty(),
    );

    mockNotificationsBloc = MockNotificationsBloc();
    when(() => mockNotificationsBloc.state).thenReturn(
      const NotificationsLoaded(
        notifications: <NotificationEntity>[],
        unreadCount: 0,
      ),
    );
    when(() => mockNotificationsBloc.stream).thenAnswer(
      (_) => const Stream<NotificationsState>.empty(),
    );  });

  tearDown(() async {
    testerViewReset();
    await offlineCubit.close();
    await GetIt.I.reset();
  });

  group('MockHomePage basic render', () {
    testWidgets('builds without crashing when authenticated', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.byType(Scaffold), findsWidgets);
      expect(find.text('Home'), findsWidgets);
    });

    testWidgets('extracts handle from AuthAuthenticated state', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
    });

    testWidgets('shows all section headers', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.textContaining('More of what you like'), findsOneWidget);
      expect(find.textContaining('Mixed for you'), findsOneWidget);
      expect(find.textContaining('Your favorite genres'), findsOneWidget);
    });
  });

  group('subscription badge', () {
    testWidgets('shows GET PRO badge for free users', (tester) async {
      await _pumpHome(
        tester,
        mockAuthCubit,
        subscription: const Subscription(
          planCode: 'FREE',
          subscriptionType: 'FREE',
          subscriptionStatus: 'ACTIVE',
          planName: 'Free',
          isPremium: false,
          canDownload: false,
          adsEnabled: true,
        ),
      );

      expect(find.text('GET PRO'), findsOneWidget);
      expect(find.text('PRO'), findsNothing);
      expect(find.text('GO+'), findsNothing);
    });

    testWidgets('tapping GET PRO badge navigates to upgrade route',
        (tester) async {
      await _pumpHome(
        tester,
        mockAuthCubit,
        subscription: const Subscription(
          planCode: 'FREE',
          subscriptionType: 'FREE',
          subscriptionStatus: 'ACTIVE',
          planName: 'Free',
          isPremium: false,
          canDownload: false,
          adsEnabled: true,
        ),
      );

      await tester.tap(find.text('GET PRO'));
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Route'), findsOneWidget);
    });

    testWidgets('shows PRO badge for pro users', (tester) async {
      await _pumpHome(
        tester,
        mockAuthCubit,
        subscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          planName: 'Pro',
          isPremium: true,
          canDownload: true,
          adsEnabled: false,
          uploadLimit: 100,
          uploadedTracks: 1,
          remainingUploads: 99,
        ),
      );

      expect(find.text('PRO'), findsOneWidget);
      expect(find.text('GET PRO'), findsNothing);
      expect(find.text('GO+'), findsNothing);
    });

    testWidgets('tapping PRO badge does not navigate away from home',
        (tester) async {
      await _pumpHome(
        tester,
        mockAuthCubit,
        subscription: const Subscription(
          planCode: 'PRO',
          subscriptionType: 'PRO',
          subscriptionStatus: 'ACTIVE',
          planName: 'Pro',
          isPremium: true,
          canDownload: true,
          adsEnabled: false,
          uploadLimit: 100,
          uploadedTracks: 1,
          remainingUploads: 99,
        ),
      );

      await tester.tap(find.text('PRO'));
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Upgrade Route'), findsNothing);
    });

    testWidgets('shows GO+ badge for go plus users', (tester) async {
      await _pumpHome(
        tester,
        mockAuthCubit,
        subscription: const Subscription(
          planCode: 'GO_PLUS',
          subscriptionType: 'GO_PLUS',
          subscriptionStatus: 'ACTIVE',
          planName: 'GO+',
          isPremium: true,
          canDownload: true,
          adsEnabled: false,
          uploadLimit: 1000,
          uploadedTracks: 1,
          remainingUploads: 999,
        ),
      );

      expect(find.text('GO+'), findsOneWidget);
      expect(find.text('GET PRO'), findsNothing);
      expect(find.text('PRO'), findsNothing);
    });
  });

  group('auth state handling', () {
    testWidgets('navigates to welcome when unauthenticated', (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthInitial());
      whenListen(
        mockAuthCubit,
        Stream<AuthState>.fromIterable([AuthUnauthenticated()]),
        initialState: AuthInitial(),
      );

      await _pumpHome(tester, mockAuthCubit);

      expect(find.text('Welcome Route'), findsOneWidget);
    });

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

    testWidgets('renders without logout button when not authenticated',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthInitial());
      when(() => mockAuthCubit.stream).thenAnswer(
        (_) => const Stream<AuthState>.empty(),
      );

      await _pumpHome(tester, mockAuthCubit);

      expect(find.byIcon(Icons.logout_rounded), findsNothing);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('shows snackbar when navigating to profile without handle',
        (tester) async {
      when(() => mockAuthCubit.state).thenReturn(AuthInitial());
      when(() => mockAuthCubit.stream).thenAnswer(
        (_) => const Stream<AuthState>.empty(),
      );

      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.byType(CircleAvatar));
      await tester.pumpAndSettle();

      expect(find.text('Please log in to view profile'), findsOneWidget);
    });
  });

  group('BottomNav navigation', () {
    testWidgets('renders all bottom nav tabs', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.text('Home'), findsWidgets);
      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Library'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(BottomNavBar),
          matching: find.text('Upgrade'),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping Feed tab navigates to feed route', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Feed'));
      await tester.pumpAndSettle();

      expect(find.text('Feed Route'), findsOneWidget);
    });

    testWidgets('tapping Search tab navigates to search route', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Search'));
      await tester.pumpAndSettle();

      expect(find.text('Search Route'), findsOneWidget);
    });

    testWidgets('tapping Library tab navigates to library route',
        (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('Library'));
      await tester.pumpAndSettle();

      expect(find.text('Library Route'), findsOneWidget);
    });

    testWidgets('tapping Upgrade tab navigates to upgrade route',
        (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(
        find.descendant(
          of: find.byType(BottomNavBar),
          matching: find.text('Upgrade'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Upgrade Route'), findsOneWidget);
    });
  });

  group('Logout bottom sheet', () {
    setUp(() {
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

  group('home content', () {
    testWidgets('tapping a genre chip updates selection', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.text('hip-hop'));
      await tester.pumpAndSettle();

      expect(find.text('hip-hop'), findsOneWidget);
    });

    testWidgets('renders related tracks and mix cards', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.text('Related tracks: L...'), findsOneWidget);
      expect(find.text('SoundCloud'), findsWidgets);
      expect(find.text('MIX 1'), findsOneWidget);
      expect(find.text('Balthazar, Cage...'), findsOneWidget);
    });

    testWidgets('tapping upload icon navigates to upload route',
        (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      await tester.tap(find.byIcon(Icons.upload_outlined));
      await tester.pumpAndSettle();

      expect(find.text('Upload Route'), findsOneWidget);
    });

    testWidgets('renders genre chips for discovery browsing', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.text('electronic'), findsOneWidget);
      expect(find.text('hip-hop'), findsOneWidget);
      expect(find.text('pop'), findsOneWidget);
    });

    testWidgets('keeps authenticated home content visible', (tester) async {
      await _pumpHome(tester, mockAuthCubit);

      expect(find.text('Home'), findsWidgets);
      expect(find.byIcon(Icons.logout_rounded), findsOneWidget);
      expect(find.text('Your favorite genres'), findsOneWidget);
    });
  });
}

void testerViewReset() {
  final binding = TestWidgetsFlutterBinding.instance;
  binding.platformDispatcher.views.first.resetPhysicalSize();
  binding.platformDispatcher.views.first.resetDevicePixelRatio();
}

class _FakeSubscriptionRepository extends SubscriptionRepository {
  _FakeSubscriptionRepository({
    required this.subscription,
  });

  final Subscription subscription;

  @override
  Future<Subscription> getMySubscription() async {
    return subscription;
  }

  @override
  Future<List<Plan>> getPlans() async {
    return const <Plan>[
      Plan(code: 'FREE', name: 'Free'),
      Plan(code: 'PRO', name: 'Pro'),
      Plan(code: 'GO_PLUS', name: 'GO+'),
    ];
  }

  @override
  Future<String> createCheckout(String plan) async {
    return 'https://checkout.example.com/$plan';
  }

  @override
  Future<String> subscribe(String plan) async {
    return 'https://subscribe.example.com/$plan';
  }

  @override
  Future<BillingPortalSession> openBillingPortalSession() async {
    return const BillingPortalSession(
      url: 'https://billing.example.com/session/test',
      sessionId: 'bps_123',
    );
  }

  @override
  Future<List<BillingInvoice>> getInvoices() async {
    return const <BillingInvoice>[];
  }

  @override
  Future<Subscription> cancelSubscription() async {
    return subscription.copyWith(
      cancelAtPeriodEnd: true,
      canResume: true,
    );
  }

  @override
  Future<Subscription> resumeSubscription() async {
    return subscription.copyWith(
      cancelAtPeriodEnd: false,
      canResume: false,
    );
  }

  @override
  Future<Subscription> changePlan(String plan) async {
    return subscription.copyWith(
      planCode: plan,
      subscriptionType: plan,
      isPremium: plan.trim().toUpperCase() != 'FREE',
    );
  }

  @override
  Future<Subscription> cancelPlanChange() async {
    return subscription.copyWith(clearPendingDowngrade: true);
  }

  @override
  Future<OfflineTrackEntitlement> getOfflineTrackEntitlement(
    String trackId,
  ) async {
    return OfflineTrackEntitlement(
      trackId: trackId,
      planCode: subscription.planCode,
    );
  }
}

class _FakeOfflineRepository implements OfflineRepository {
  @override
  DioClient get dio => throw UnimplementedError();

  @override
  Future<String> downloadTrack(String trackId) async {
    return '/offline/$trackId.mp3';
  }

  @override
  Future<Track?> fetchTrackDetails(String trackId) async {
    return null;
  }

  @override
  Future<Map<String, String>> getDownloadedTracks() async {
    return const <String, String>{};
  }

  @override
  Future<void> saveDownloadedTracks(Map<String, String> data) async {}

  @override
  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    return const <String, Track>{};
  }

  @override
  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {}

  @override
  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    return const <String, PlaylistEntity>{};
  }

  @override
  Future<void> saveDownloadedPlaylists(
    Map<String, PlaylistEntity> data,
  ) async {}
}
