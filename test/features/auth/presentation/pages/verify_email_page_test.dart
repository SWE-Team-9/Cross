import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/verify_email_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.remainingResendSeconds).thenReturn(0);
    when(() => authCubit.sendEmailVerification(email: any(named: 'email')))
        .thenAnswer((_) async {});
    when(() => authCubit.logout()).thenAnswer((_) async {});
  });

  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: AuthRoutes.verifyEmail,
      routes: [
        GoRoute(
          path: AuthRoutes.verifyEmail,
          builder: (_, __) => BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: const VerifyEmailPage(email: 'ali@example.com'),
          ),
        ),
        GoRoute(
          path: AuthRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('login-page')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('VerifyEmailPage', () {
    testWidgets('renders email verification UI', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Check Your Email'), findsOneWidget);
      expect(find.text('ali@example.com'), findsOneWidget);
      expect(find.text('Go to Login'), findsOneWidget);
    });

    testWidgets('auto sends verification email when no cooldown is active',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      verify(() => authCubit.sendEmailVerification(email: 'ali@example.com'))
          .called(1);
    });

    testWidgets('shows countdown text when cooldown is active', (tester) async {
      when(() => authCubit.remainingResendSeconds).thenReturn(30);

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.textContaining('Resend link in'), findsOneWidget);
      verifyNever(
          () => authCubit.sendEmailVerification(email: 'ali@example.com'));
    });

    testWidgets('Go to Login button triggers logout', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Go to Login'));
      await tester.pump();

      verify(() => authCubit.logout()).called(1);
    });

    testWidgets('shows snackbar when verification email is sent',
        (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([
          AuthVerificationEmailSent('ali@example.com'),
        ]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(
        find.text('A verification link has been sent to your email.'),
        findsOneWidget,
      );
    });

    testWidgets('shows snackbar on AuthError', (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([
          AuthError('Too many requests'),
        ]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Too many requests'), findsOneWidget);
    });

    testWidgets('navigates to login when AuthUnauthenticated is emitted',
        (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([
          AuthUnauthenticated(),
        ]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}
