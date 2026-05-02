import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:soundcloud_clone/app/router.dart' as app_router;
import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_service.dart';
import 'package:soundcloud_clone/core/models/player_state.dart';
import 'package:soundcloud_clone/core/models/track.dart';
import 'package:soundcloud_clone/core/services/audio_player_service.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/login_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/register_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/reset_password_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/verify_email_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';
import 'package:soundcloud_clone/features/feed/presentation/pages/feed_page.dart';
import 'package:soundcloud_clone/features/library/presentation/pages/library_page.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_cubit.dart';
import 'package:soundcloud_clone/features/library/presentation/bloc/library_state.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/realtime_message_event_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/entities/unread_count_entity.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/connect_messaging_socket_usecase.dart';
import 'package:soundcloud_clone/features/messaging/domain/usecases/get_unread_count_usecase.dart';
import 'package:soundcloud_clone/features/messaging/presentation/bloc/unread_count_cubit.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';
import 'package:soundcloud_clone/features/playlists/domain/entities/playlist_entity.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/profile_page.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/search/presentation/pages/mock_search_page.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/followers_page.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/following_page.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/track_management_state.dart';
import 'package:soundcloud_clone/core/network/dio_client.dart';
import 'package:soundcloud_clone/features/offline/data/repositories/offline_repository.dart';
import 'package:soundcloud_clone/features/offline/presentation/bloc/offline_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_cubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/upload_picker_state.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/upload_picker_page.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  double _currentVolume = 1;

  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

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

class FakeOfflineRepository implements OfflineRepository {
  @override
  late final DioClient dio;

  final Map<String, String> _storage = {};
  final Map<String, Track> _trackDetails = {};
  final Map<String, PlaylistEntity> _playlists = {};

  @override
  Future<String> downloadTrack(String trackId) async {
    final path = '/fake/$trackId.mp3';
    _storage[trackId] = path;
    return path;
  }

  @override
  Future<Track?> fetchTrackDetails(String trackId) async {
    return _trackDetails[trackId];
  }

  @override
  Future<Map<String, String>> getDownloadedTracks() async {
    return _storage;
  }

  @override
  Future<void> saveDownloadedTracks(Map<String, String> data) async {
    _storage
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, Track>> getDownloadedTrackDetails() async {
    return _trackDetails;
  }

  @override
  Future<void> saveDownloadedTrackDetails(Map<String, Track> data) async {
    _trackDetails
      ..clear()
      ..addAll(data);
  }

  @override
  Future<Map<String, PlaylistEntity>> getDownloadedPlaylists() async {
    return _playlists;
  }

  @override
  Future<void> saveDownloadedPlaylists(Map<String, PlaylistEntity> data) async {
    _playlists
      ..clear()
      ..addAll(data);
  }
}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockLibraryCubit extends MockCubit<LibraryState>
    implements LibraryCubit {}

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockUploadPickerCubit extends MockCubit<UploadPickerState>
    implements UploadPickerCubit {}

class MockTrackManagementCubit extends MockCubit<TrackManagementState>
    implements TrackManagementCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

class MockGetUnreadCountUseCase extends Mock implements GetUnreadCountUseCase {}

class MockConnectMessagingSocketUseCase extends Mock
    implements ConnectMessagingSocketUseCase {}

void main() {
  late MockAuthCubit authCubit;
  late MockLibraryCubit libraryCubit;
  late MockProfileCubit profileCubit;
  late MockUploadPickerCubit uploadPickerCubit;
  late MockTrackManagementCubit trackManagementCubit;
  late MockSocialRepo mockSocialRepo;
  late MockGetUnreadCountUseCase getUnreadCountUseCase;
  late MockConnectMessagingSocketUseCase connectMessagingSocketUseCase;

  final authenticatedUser = AuthAuthenticated(
    const User(
      id: '1',
      email: 'ali@example.com',
      handle: 'ali',
      displayName: 'Ali',
      avatarUrl: null,
    ),
  );

  setUp(() async {
    await GetIt.I.reset();

    mockSocialRepo = MockSocialRepo();
    authCubit = MockAuthCubit();
    libraryCubit = MockLibraryCubit();
    profileCubit = MockProfileCubit();
    uploadPickerCubit = MockUploadPickerCubit();
    trackManagementCubit = MockTrackManagementCubit();
    getUnreadCountUseCase = MockGetUnreadCountUseCase();
    connectMessagingSocketUseCase = MockConnectMessagingSocketUseCase();

    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );
    GetIt.I.registerSingleton<DeepLinkService>(
      FakeDeepLinkService(),
    );
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );
    when(() => libraryCubit.state).thenReturn(LibraryState.initial());
    when(() => libraryCubit.stream).thenAnswer(
      (_) => const Stream<LibraryState>.empty(),
    );
    when(() => libraryCubit.loadLibraryPlaylists()).thenAnswer((_) async {});
    when(() => libraryCubit.close()).thenAnswer((_) async {});

    GetIt.I.registerFactory<LibraryCubit>(() => libraryCubit);
    GetIt.I.registerLazySingleton<SubscriptionRepository>(
      () => MockSubscriptionRepository(),
    );

    GetIt.I.registerFactory<TrackManagementCubit>(() => trackManagementCubit);

    GetIt.I.registerFactory<UnreadCountCubit>(
      () => UnreadCountCubit(
        getUnreadCountUseCase: getUnreadCountUseCase,
        connectMessagingSocketUseCase: connectMessagingSocketUseCase,
      ),
    );

    when(() => getUnreadCountUseCase()).thenAnswer(
      (_) async => const UnreadCountEntity(count: 0),
    );

    when(() => connectMessagingSocketUseCase()).thenAnswer((_) async {});

    when(() => connectMessagingSocketUseCase.eventsStream).thenAnswer(
      (_) => const Stream<RealtimeMessageEventEntity>.empty(),
    );

    when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
    when(() => authCubit.remainingResendSeconds).thenReturn(0);

    when(() => authCubit.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async {});

    when(
      () => authCubit.resetPassword(
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
        newPasswordConfirm: any(named: 'newPasswordConfirm'),
      ),
    ).thenAnswer((_) async {});

    when(() => authCubit.verifyEmail(code: any(named: 'code')))
        .thenAnswer((_) async {});

    when(() => authCubit.sendEmailVerification(email: any(named: 'email')))
        .thenAnswer((_) async {});

    when(() => profileCubit.state).thenReturn(ProfileInitial());
    when(() => profileCubit.stream)
        .thenAnswer((_) => const Stream<ProfileState>.empty());
    when(() => profileCubit.loadOwnProfile()).thenAnswer((_) async {});
    when(() => profileCubit.loadProfile(any())).thenAnswer((_) async {});

    when(() => uploadPickerCubit.state).thenReturn(const UploadPickerState());
    when(() => uploadPickerCubit.stream)
        .thenAnswer((_) => const Stream<UploadPickerState>.empty());

    when(() => trackManagementCubit.state)
        .thenReturn(const TrackManagementState());
    when(() => trackManagementCubit.stream)
        .thenAnswer((_) => const Stream<TrackManagementState>.empty());
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  Future<void> pumpRouter(
    WidgetTester tester, {
    required AuthState authState,
    String? initialLocation,
    Object? extra,
  }) async {
    tester.view.physicalSize = const Size(1200, 1800);
    tester.view.devicePixelRatio = 1.0;

    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    when(() => authCubit.state).thenReturn(authState);
    whenListen(
      authCubit,
      Stream<AuthState>.fromIterable([authState]),
      initialState: authState,
    );

    if (!GetIt.I.isRegistered<ProfileCubit>()) {
      GetIt.I.registerSingleton<ProfileCubit>(profileCubit);
    }

    if (!GetIt.I.isRegistered<UnreadCountCubit>()) {
      GetIt.I.registerFactory<UnreadCountCubit>(
        () => UnreadCountCubit(
          getUnreadCountUseCase: getUnreadCountUseCase,
          connectMessagingSocketUseCase: connectMessagingSocketUseCase,
        ),
      );
    }

    if (!GetIt.I.isRegistered<OfflineCubit>()) {
      GetIt.I.registerSingleton<OfflineCubit>(
        OfflineCubit(FakeOfflineRepository()),
      );
    }

    if (!GetIt.I.isRegistered<SubscriptionCubit>()) {
      GetIt.I.registerSingleton<SubscriptionCubit>(
        SubscriptionCubit(GetIt.I<SubscriptionRepository>())
          ..loadSubscription(),
      );
    }

    final router = app_router.createRouter();

    if (initialLocation != null) {
      router.go(initialLocation, extra: extra);
    }

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: authCubit),
          BlocProvider<ProfileCubit>.value(value: profileCubit),
          BlocProvider<UploadPickerCubit>.value(value: uploadPickerCubit),
          Provider<SocialRepo>.value(value: mockSocialRepo),
          BlocProvider<SubscriptionCubit>.value(
            value: GetIt.I<SubscriptionCubit>(),
          ),
        ],
        child: BlocProvider<PlayerCubit>(
          create: (_) => PlayerCubit(GetIt.I<AudioPlayerService>()),
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  Future<void> pumpRouteChange(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));
    await tester.pump(const Duration(milliseconds: 300));
  }

  group('AppRouter Tests', () {
    testWidgets('starts at splash page and calls checkAuthStatus',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([AuthInitial()]),
        initialState: AuthInitial(),
      );

      final router = app_router.createRouter();

      await tester.pumpWidget(
        MultiBlocProvider(
          providers: [
            BlocProvider<AuthCubit>.value(value: authCubit),
            BlocProvider<PlayerCubit>(
              create: (_) => PlayerCubit(GetIt.I<AudioPlayerService>()),
            ),
            BlocProvider<SubscriptionCubit>(
              create: (_) => SubscriptionCubit(MockSubscriptionRepository())
                ..loadSubscription(),
            ),
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );

      await tester.pump();

      verify(() => authCubit.checkAuthStatus()).called(1);
    });

    testWidgets('shows 404 fallback for unknown route', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: '/definitely-missing-route',
      );

      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Go Home'), findsOneWidget);
    });

    testWidgets('can navigate to library route directly', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.library,
      );

      expect(find.byType(LibraryPage), findsOneWidget);
    });

    testWidgets('can navigate to home route directly', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.home,
      );

      expect(find.text('GET PRO'), findsOneWidget);
      expect(find.text('More of what you like'), findsOneWidget);
    });

    testWidgets('can navigate to login route directly', (tester) async {
      await pumpRouter(
        tester,
        authState: AuthUnauthenticated(),
        initialLocation: AuthRoutes.login,
      );

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('can navigate to register route directly', (tester) async {
      await pumpRouter(
        tester,
        authState: AuthUnauthenticated(),
        initialLocation: AuthRoutes.register,
      );

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('can navigate to forgot password route directly',
        (tester) async {
      await pumpRouter(
        tester,
        authState: AuthUnauthenticated(),
        initialLocation: AuthRoutes.forgotPassword,
      );

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('can navigate to reset password route with extra',
        (tester) async {
      await pumpRouter(
        tester,
        authState: AuthUnauthenticated(),
        initialLocation: AuthRoutes.resetPassword,
        extra: 'ali@example.com',
      );

      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });

    testWidgets('can navigate to verify email route with extra',
        (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: AuthRoutes.verifyEmail,
        extra: 'ali@example.com',
      );

      expect(find.byType(VerifyEmailPage), findsOneWidget);
    });

    testWidgets('can navigate to complete profile route with extra',
        (tester) async {
      await pumpRouter(
        tester,
        authState: AuthUnauthenticated(),
        initialLocation: AuthRoutes.completeProfile,
        extra: <String, String>{
          'email': 'ali@example.com',
          'password': 'Pass@123',
        },
      );

      expect(find.byType(CompleteProfilePage), findsOneWidget);
    });

    testWidgets('can navigate to edit profile route', (tester) async {
      when(() => profileCubit.state).thenReturn(ProfileInitial());
      when(() => profileCubit.stream)
          .thenAnswer((_) => const Stream<ProfileState>.empty());

      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.editProfile,
        extra: profileCubit,
      );

      expect(find.byType(EditProfilePage), findsOneWidget);
    });

    testWidgets('can navigate to profile page with handle', (tester) async {
      when(() => profileCubit.state).thenReturn(ProfileInitial());
      when(() => profileCubit.stream)
          .thenAnswer((_) => const Stream<ProfileState>.empty());

      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: '/profile/ali',
      );

      expect(find.byType(ProfilePage), findsOneWidget);
    });

    testWidgets('can navigate to followers page', (tester) async {
      when(() => profileCubit.state).thenReturn(ProfileInitial());
      when(() => profileCubit.stream)
          .thenAnswer((_) => const Stream<ProfileState>.empty());

      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: '/followers/ali',
      );

      expect(find.byType(FollowersPage), findsOneWidget);
    });

    testWidgets('can navigate to following page', (tester) async {
      when(() => profileCubit.state).thenReturn(ProfileInitial());
      when(() => profileCubit.stream)
          .thenAnswer((_) => const Stream<ProfileState>.empty());

      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: '/following/ali',
      );

      expect(find.byType(FollowingPage), findsOneWidget);
    });

    testWidgets('can navigate to upload picker page', (tester) async {
      when(() => uploadPickerCubit.state).thenReturn(const UploadPickerState());
      when(() => uploadPickerCubit.stream)
          .thenAnswer((_) => const Stream<UploadPickerState>.empty());

      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.uploadPicker,
      );

      expect(find.byType(UploadPickerPage), findsOneWidget);
    });

    testWidgets('can navigate to feed page', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.feed,
      );

      expect(find.byType(FeedPage), findsOneWidget);
    });

    testWidgets('can navigate to search page', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.search,
      );

      expect(find.byType(MockSearchPage), findsOneWidget);
    });

    testWidgets('search route reads query parameter from url', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: '/search?q=edm',
      );

      expect(find.byType(MockSearchPage), findsOneWidget);
    });

    testWidgets('can navigate to upgrade placeholder', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.upgrade,
      );

      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Upgrade to IQA3 Pro'), findsOneWidget);
    });

    testWidgets('404 fallback Go Home button navigates home', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: '/missing-route',
      );

      await tester.tap(find.text('Go Home'));
      await pumpRouteChange(tester);

      expect(find.text('GET PRO'), findsOneWidget);
    });
  });
}
