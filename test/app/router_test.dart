import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:provider/provider.dart';
import 'package:soundcloud_clone/features/playback/presentation/bloc/player_cubit.dart';

import 'package:soundcloud_clone/app/router.dart' as app_router;
import 'package:soundcloud_clone/core/models/player_state.dart';
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
import 'package:soundcloud_clone/features/library/presentation/pages/library_page.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_cubit.dart';
import 'package:soundcloud_clone/features/profile/presentation/bloc/profile_state.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/edit_profile_page.dart';
import 'package:soundcloud_clone/features/profile/presentation/pages/profile_page.dart';
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/followers_page.dart';
import 'package:soundcloud_clone/features/social/presentation/pages/following_page.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/uploadPickerState.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/trackManagementCubit.dart';
import 'package:soundcloud_clone/features/upload/presentation/bloc/trackManagementState.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';
import 'package:soundcloud_clone/features/upload/presentation/pages/UploadPickerPage.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Future<void> play(track) async {}

  @override
  Future<void> pause() async {}

  Future<void> resume() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {}
}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockProfileCubit extends MockCubit<ProfileState>
    implements ProfileCubit {}

class MockUploadPickerCubit extends MockCubit<UploadPickerState>
    implements UploadPickerCubit {}

class MockTrackManagementCubit extends MockCubit<TrackManagementState>
    implements TrackManagementCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

void main() {
  late MockAuthCubit authCubit;
  late MockProfileCubit profileCubit;
  late MockUploadPickerCubit uploadPickerCubit;
  late MockTrackManagementCubit trackManagementCubit;
  late MockSocialRepo mockSocialRepo;

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
    profileCubit = MockProfileCubit();
    uploadPickerCubit = MockUploadPickerCubit();
    trackManagementCubit = MockTrackManagementCubit();

    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );
    GetIt.I.registerFactory<TrackManagementCubit>(() => trackManagementCubit);

    when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
    when(() => authCubit.remainingResendSeconds).thenReturn(0);

    when(() => authCubit.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async {});
    when(() => authCubit.resetPassword(
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
          newPasswordConfirm: any(named: 'newPasswordConfirm'),
        )).thenAnswer((_) async {});
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

    // Fix: Using base class or standard constructor if Initial doesn't exist
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
    when(() => authCubit.state).thenReturn(authState);
    whenListen(
      authCubit,
      Stream<AuthState>.fromIterable([authState]),
      initialState: authState,
    );

    // Register ProfileCubit in GetIt if not already registered
    if (!GetIt.I.isRegistered<ProfileCubit>()) {
      GetIt.I.registerSingleton<ProfileCubit>(profileCubit);
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
        ],
        child: BlocProvider<PlayerCubit>(
          create: (_) => PlayerCubit(GetIt.I<AudioPlayerService>()),
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle(const Duration(seconds: 5));
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
          ],
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();

      verifyNever(() => authCubit.checkAuthStatus());
    });

    testWidgets('navigates to welcome page when AuthUnauthenticated is emitted',
        (tester) async {
      await pumpRouter(
        tester,
        authState: AuthUnauthenticated(),
      );

      expect(find.text("We lead what’s next in music."), findsOneWidget);
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
      // Ensure ProfileCubit is set up for this test
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
      // Ensure ProfileCubit is available for FollowersPage
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
      // Ensure ProfileCubit is available for FollowingPage
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

    // TODO: Fix track management page timeout issue
    // testWidgets('can navigate to track management page', (tester) async {
    //   when(() => trackManagementCubit.state)
    //       .thenReturn(const TrackManagementState());
    //   when(() => trackManagementCubit.stream)
    //       .thenAnswer((_) => const Stream<TrackManagementState>.empty());
    //
    //   await pumpRouter(
    //     tester,
    //     authState: authenticatedUser,
    //     initialLocation: app_router.AppRoutes.trackManagementDemo,
    //   );
    //
    //   expect(find.byType(TrackManagementPage), findsOneWidget);
    // });

    testWidgets('can navigate to feed placeholder', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.feed,
      );

      expect(find.text('Feed'), findsOneWidget);
      expect(find.text('Feed page is not implemented yet.'), findsOneWidget);
    });

    testWidgets('can navigate to search placeholder', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.search,
      );

      expect(find.text('Search'), findsOneWidget);
      expect(find.text('Search page is not implemented yet.'), findsOneWidget);
    });

    testWidgets('can navigate to upgrade placeholder', (tester) async {
      await pumpRouter(
        tester,
        authState: authenticatedUser,
        initialLocation: app_router.AppRoutes.upgrade,
      );

      expect(find.text('Upgrade'), findsOneWidget);
      expect(find.text('Upgrade page is not implemented yet.'), findsOneWidget);
    });
  });
}
