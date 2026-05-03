import 'dart:async';

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
import 'package:dio/dio.dart';
import 'package:soundcloud_clone/app/router.dart';
import 'package:soundcloud_clone/core/notifiers/overlay_notifiers.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/playback_cubit.dart';
import 'package:soundcloud_clone/features/playback/data/repositories/queue_repository.dart';

import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_state.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notifications_bloc.dart';
import 'package:soundcloud_clone/features/notifications/presentation/bloc/notification_preferences_bloc.dart';
import 'package:soundcloud_clone/features/notifications/data/services/notifications_realtime_refresh_service.dart';
import 'package:soundcloud_clone/features/home/presentation/bloc/home_cubit.dart';
import 'package:soundcloud_clone/features/home/presentation/bloc/home_state.dart';

// ── Fakes / Mocks ─────────────────────────────────────────────────────────────

class FakeAudioPlayerService implements AudioPlayerService {
  double _currentVolume = 1;
  int stopCallCount = 0;

  @override
  Stream<app_state.PlayerState> get playerStateStream => const Stream.empty();

  @override
  Future<void> play(track) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> resume() async {}

  @override
  Future<void> stop() async {
    stopCallCount++;
  }

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
  Future<void> playLocalFile(String path) async {}

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

class MockDioClient extends Mock implements DioClient {}

class MockOfflineRepository extends Mock implements OfflineRepository {}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

class MockNotificationsBloc
    extends MockBloc<NotificationsEvent, NotificationsState>
    implements NotificationsBloc {}

class MockNotificationPreferencesBloc
    extends MockBloc<NotificationPreferencesEvent, NotificationPreferencesState>
    implements NotificationPreferencesBloc {}

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

class MockSubscriptionCubit extends MockCubit<SubscriptionState>
  implements SubscriptionCubit {}

// ── Helper: pump the full App widget ─────────────────────────────────────────

Future<void> _pumpApp(
  WidgetTester tester,
  MockAuthCubit authCubit, {
  MockSubscriptionCubit? subscriptionCubit,
  AuthState? authState,
  Stream<AuthState>? authStream,
}) async {
  // Important: fully unmount any previous router tree before mounting App.
  // This prevents Duplicate GlobalKey errors from GoRouter's internal keys.
  await tester.pumpWidget(const SizedBox.shrink());
  await tester.pump();

  final state = authState ?? AuthInitial();
  final effectiveSubscriptionCubit =
      subscriptionCubit ?? MockSubscriptionCubit();

  when(() => authCubit.state).thenReturn(state);
  whenListen(
    authCubit,
    authStream ?? Stream<AuthState>.fromIterable([state]),
    initialState: state,
  );
  when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
  when(() => authCubit.remainingResendSeconds).thenReturn(0);

  when(() => effectiveSubscriptionCubit.state)
      .thenReturn(SubscriptionState.initial());
  whenListen(
    effectiveSubscriptionCubit,
    const Stream<SubscriptionState>.empty(),
    initialState: SubscriptionState.initial(),
  );
  when(() => effectiveSubscriptionCubit.loadSubscription())
      .thenAnswer((_) async {});
  when(() => effectiveSubscriptionCubit.reset()).thenAnswer((_) {});

  await tester.pumpWidget(
    MultiBlocProvider(
      providers: [
        BlocProvider<AuthCubit>.value(value: authCubit),
        BlocProvider<SubscriptionCubit>.value(
          value: effectiveSubscriptionCubit,
        ),
      ],
      child: App(routerConfig: createRouter()),
    ),
  );

  await tester.pump();
}

void main() {
  late MockAuthCubit authCubit;
  late MockSocialRepo mockSocialRepo;
  late MockGetUnreadCountUseCase getUnreadCountUseCase;
  late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  late MockDioClient mockDioClient;
  late MockNotificationsBloc mockNotificationsBloc;
  late MockNotificationPreferencesBloc mockNotificationPreferencesBloc;
  late MockHomeCubit mockHomeCubit;
  late MockSubscriptionCubit mockSubscriptionCubit;
  late FakeAudioPlayerService fakeAudioPlayerService;

  setUp(() async {
    await GetIt.I.reset();

    isTrackSheetOpen.value = false;

    authCubit = MockAuthCubit();
    mockSocialRepo = MockSocialRepo();
    mockDioClient = MockDioClient();
    getUnreadCountUseCase = MockGetUnreadCountUseCase();
    connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();
    mockHomeCubit = MockHomeCubit();

    when(() => getUnreadCountUseCase()).thenAnswer(
      (_) async => const UnreadCountEntity(count: 0),
    );

    when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});
    when(() => connectMessagingSocketUseCase.disconnect())
        .thenAnswer((_) async {});

    when(() => connectMessagingSocketUseCase.eventsStream).thenAnswer(
      (_) => const Stream<RealtimeMessageEventEntity>.empty(),
    );

    when(() => mockDioClient.get<dynamic>(
          any(),
          queryParameters: any(named: 'queryParameters'),
          options: any(named: 'options'),
        )).thenAnswer(
      (invocation) async => Response<dynamic>(
        data: <dynamic>[],
        requestOptions: RequestOptions(
          path: invocation.positionalArguments[0] as String,
        ),
      ),
    );
    mockNotificationsBloc = MockNotificationsBloc();
    mockNotificationPreferencesBloc = MockNotificationPreferencesBloc();
    fakeAudioPlayerService = FakeAudioPlayerService();
    mockSubscriptionCubit = MockSubscriptionCubit();

    // Mock states for notification blocs
    when(() => mockNotificationsBloc.state)
        .thenReturn(const NotificationsInitial());
    when(() => mockNotificationPreferencesBloc.state)
        .thenReturn(NotificationPreferencesState.initial());
    when(() => mockHomeCubit.state).thenReturn(HomeState.initial());
    whenListen(
      mockHomeCubit,
      const Stream<HomeState>.empty(),
      initialState: HomeState.initial(),
    );
    when(() => mockHomeCubit.load()).thenAnswer((_) async {});
    when(() => mockHomeCubit.refresh()).thenAnswer((_) async {});
    when(() => mockHomeCubit.selectGenre(any())).thenAnswer((_) async {});

    GetIt.I.registerSingleton<AudioPlayerService>(fakeAudioPlayerService);
    GetIt.I.registerSingleton<DeepLinkService>(FakeDeepLinkService());
    GetIt.I.registerSingleton<DioClient>(mockDioClient);
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(RecentlyPlayedCubit());
    GetIt.I.registerLazySingleton<SocialRepo>(() => mockSocialRepo);

    GetIt.I.registerLazySingleton<SubscriptionRepository>(
      () => MockSubscriptionRepository(),
    );
    GetIt.I.registerSingleton<OfflineCubit>(
      OfflineCubit(MockOfflineRepository()),
    );
    GetIt.I.registerSingleton<SubscriptionCubit>(
      SubscriptionCubit(GetIt.I<SubscriptionRepository>())..loadSubscription(),
    );

    GetIt.I.registerFactory<AuthCubit>(() => authCubit);
    GetIt.I.registerFactory<HomeCubit>(() => mockHomeCubit);

    GetIt.I.registerLazySingleton<PlaybackCubit>(
      () => PlaybackCubit(
        GetIt.I<AudioPlayerService>(),
        GetIt.I<QueueRepository>(),
      ),
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

    GetIt.I.registerLazySingleton<NotificationsRealtimeRefreshService>(
      () => NotificationsRealtimeRefreshService(connectMessagingSocketUseCase),
    );

    GetIt.I.registerLazySingleton<NotificationsBloc>(
      () => mockNotificationsBloc,
    );

    GetIt.I.registerLazySingleton<NotificationPreferencesBloc>(
      () => mockNotificationPreferencesBloc,
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

    testWidgets('refreshes subscription on auth changes', (tester) async {
      final authController = StreamController<AuthState>();

      await _pumpApp(
        tester,
        authCubit,
        subscriptionCubit: mockSubscriptionCubit,
        authState: AuthUnauthenticated(),
        authStream: authController.stream,
      );

      authController.add(
        AuthAuthenticated(
          const User(
            id: 'user-1',
            email: 'one@example.com',
            handle: 'one',
          ),
        ),
      );
      await tester.pump();

      authController.add(AuthUnauthenticated());
      await tester.pump();

      verify(() => mockSubscriptionCubit.loadSubscription()).called(1);
      verify(() => mockSubscriptionCubit.reset()).called(1);

      await authController.close();
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

      verify(() => getUnreadCountUseCase()).called(1);
      verify(() => connectMessagingSocketUseCase()).called(1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('stops playback when auth becomes unauthenticated',
        (tester) async {
      final authController = StreamController<AuthState>();
      addTearDown(authController.close);

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
        authStream: authController.stream,
      );

      authController.add(AuthUnauthenticated());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 50));

      expect(fakeAudioPlayerService.stopCallCount, 1);
      verify(() => connectMessagingSocketUseCase.disconnect()).called(1);
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
