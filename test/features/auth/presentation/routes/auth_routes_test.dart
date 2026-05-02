import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/deep_links/deep_link_destination.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/complete_profile_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/login_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/oauth_debug_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/register_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/reset_password_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/splash_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/verify_email_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/welcome_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUpAll(() {
    // استخدمنا نسخة حقيقية من الكلاس بدل الـ Fake عشان نتفادى مشكلة الـ final class
    registerFallbackValue(
        const OAuthCallbackDeepLink(code: 'dummy', state: 'dummy'));
  });

  setUp(() {
    authCubit = MockAuthCubit();

    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
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
    when(() => authCubit.remainingResendSeconds).thenReturn(0);

    when(() => authCubit.handleOAuthCallbackDeepLink(any()))
        .thenAnswer((_) async {});
  });

  Widget buildApp(String initialLocation, {Object? extra}) {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: AuthRoutes.routes,
      initialExtra: extra,
    );

    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(routerConfig: router),
    );
  }

  group('AuthRoutes constants', () {
    test('exposes expected route paths', () {
      expect(AuthRoutes.splash, '/');
      expect(AuthRoutes.welcome, '/welcome');
      expect(AuthRoutes.login, '/login');
      expect(AuthRoutes.register, '/register');
      expect(AuthRoutes.completeProfile, '/complete-profile');
      expect(AuthRoutes.forgotPassword, '/forgot-password');
      expect(AuthRoutes.resetPassword, '/reset-password');
      expect(AuthRoutes.verifyEmail, '/verify-email');
      expect(AuthRoutes.oauthDebug, '/oauth-debug');
    });

    test('contains expected number of routes', () {
      expect(AuthRoutes.routes.length, 9);
    });
  });

  group('AuthRoutes route builders', () {
    testWidgets('builds splash page', (tester) async {
      await tester.pumpWidget(buildApp(AuthRoutes.splash));
      await tester.pump();

      expect(find.byType(SplashPage), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('builds welcome page', (tester) async {
      await tester.pumpWidget(buildApp(AuthRoutes.welcome));
      await tester.pumpAndSettle();

      expect(find.byType(WelcomePage), findsOneWidget);
    });

    testWidgets('builds login page', (tester) async {
      await tester.pumpWidget(buildApp(AuthRoutes.login));
      await tester.pumpAndSettle();

      expect(find.byType(LoginPage), findsOneWidget);
    });

    testWidgets('builds register page', (tester) async {
      await tester.pumpWidget(buildApp(AuthRoutes.register));
      await tester.pumpAndSettle();

      expect(find.byType(RegisterPage), findsOneWidget);
    });

    testWidgets('builds complete profile page with registration data',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          AuthRoutes.completeProfile,
          extra: <String, String>{
            'email': 'ali@example.com',
            'password': 'Pass@123',
          },
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CompleteProfilePage), findsOneWidget);
    });

    testWidgets('builds forgot password page', (tester) async {
      await tester.pumpWidget(buildApp(AuthRoutes.forgotPassword));
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPasswordPage), findsOneWidget);
    });

    testWidgets('builds reset password page with email extra', (tester) async {
      await tester.pumpWidget(
        buildApp(
          AuthRoutes.resetPassword,
          extra: 'ali@example.com',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ResetPasswordPage), findsOneWidget);
    });

    testWidgets('builds verify email page with email extra', (tester) async {
      await tester.pumpWidget(
        buildApp(
          AuthRoutes.verifyEmail,
          extra: 'ali@example.com',
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(VerifyEmailPage), findsOneWidget);
    });

    testWidgets('builds oauth debug page with destination extra',
        (tester) async {
      await tester.pumpWidget(
        buildApp(
          AuthRoutes.oauthDebug,
          extra: const OAuthCallbackDeepLink(code: 'test', state: 'test'),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OAuthDebugPage), findsOneWidget);
    });
  });
}
