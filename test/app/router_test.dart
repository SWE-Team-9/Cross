import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
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
import 'package:soundcloud_clone/features/recently_played/presentation/bloc/recently_played_cubit.dart';

class FakeAudioPlayerService implements AudioPlayerService {
  @override
  Stream<PlayerState> get playerStateStream => const Stream.empty();

  @override
  Future<void> play(track) async {}

  @override
  Future<void> pause() async {}

  @override
  Future<void> stop() async {}

  @override
  Future<void> seek(Duration position) async {}

  @override
  Future<void> dispose() async {}
}

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerSingleton<AudioPlayerService>(
      FakeAudioPlayerService(),
    );
    GetIt.I.registerSingleton<RecentlyPlayedCubit>(
      RecentlyPlayedCubit(),
    );

    authCubit = MockAuthCubit();

    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
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

    app_router.router.go(AuthRoutes.splash);
  });

  tearDown(() async {
    await GetIt.I.reset();
    app_router.router.go(AuthRoutes.splash);
  });

  Widget buildRouterApp() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(
        routerConfig: app_router.router,
      ),
    );
  }

  group('AppRouter Tests', () {
    testWidgets('starts at splash page and calls checkAuthStatus',
        (tester) async {
      await tester.pumpWidget(buildRouterApp());
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verify(() => authCubit.checkAuthStatus()).called(1);
    });

    testWidgets('navigates to welcome page when AuthUnauthenticated is emitted',
        (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([AuthUnauthenticated()]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.text("We lead what’s next in music."), findsOneWidget);
    });

    testWidgets('shows 404 fallback for unknown route', (tester) async {
      app_router.router.go('/definitely-missing-route');

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.text('Page not found'), findsOneWidget);
      expect(find.text('Go Home'), findsOneWidget);
    });

    testWidgets('can navigate to library route directly', (tester) async {
      app_router.router.go(app_router.AppRoutes.library);

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(LibraryPage), findsOneWidget);
      expect(find.text('Library'), findsAtLeastNWidgets(1));
    });

    testWidgets('can navigate to home route directly', (tester) async {
      when(() => authCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      app_router.router.go(app_router.AppRoutes.home);

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.text('GET PRO'), findsOneWidget);
      expect(find.text('More of what you like'), findsOneWidget);
    });

    testWidgets('404 fallback Go Home button navigates to home',
        (tester) async {
      when(() => authCubit.state).thenReturn(
        AuthAuthenticated(
          const User(
            id: '1',
            email: 'ali@example.com',
            handle: 'ali',
            displayName: 'Ali',
            avatarUrl: null,
          ),
        ),
      );

      app_router.router.go('/another-missing-route');

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.text('Page not found'), findsOneWidget);

      await tester.tap(find.text('Go Home'));
      await tester.pumpAndSettle();

      expect(find.text('GET PRO'), findsOneWidget);
    });

    testWidgets('can navigate to login route directly', (tester) async {
      app_router.router.go(AuthRoutes.login);

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('can navigate to register route directly', (tester) async {
      app_router.router.go(AuthRoutes.register);

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('can navigate to forgot password route directly',
        (tester) async {
      app_router.router.go(AuthRoutes.forgotPassword);

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('can navigate to reset password route with extra',
        (tester) async {
      app_router.router.go(
        AuthRoutes.resetPassword,
        extra: 'ali@example.com',
      );

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });

    testWidgets('can navigate to verify email route with extra',
        (tester) async {
      app_router.router.go(
        AuthRoutes.verifyEmail,
        extra: 'ali@example.com',
      );

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailPage), findsOneWidget);
    });

    testWidgets('can navigate to complete profile route with extra',
        (tester) async {
      app_router.router.go(
        AuthRoutes.completeProfile,
        extra: <String, String>{
          'email': 'ali@example.com',
          'password': 'Pass@123',
        },
      );

      await tester.pumpWidget(buildRouterApp());
      await tester.pumpAndSettle();

      expect(find.byType(CompleteProfilePage), findsOneWidget);
    });
  });
}
