import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/reset_password_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(
      () => authCubit.resetPassword(
        email: any(named: 'email'),
        code: any(named: 'code'),
        newPassword: any(named: 'newPassword'),
      ),
    ).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({
    required AuthCubit cubit,
    Widget? child,
    GoRouter? router,
  }) {
    if (router != null) {
      return BlocProvider<AuthCubit>.value(
        value: cubit,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    return BlocProvider<AuthCubit>.value(
      value: cubit,
      child: MaterialApp(
        home: child ?? const ResetPasswordPage(email: 'test@example.com'),
      ),
    );
  }

  group('ResetPasswordPage', () {
    testWidgets('renders page content', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.text('Reset Password'), findsWidgets);
      expect(find.text('Reset password for test@example.com'), findsOneWidget);
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
      expect(find.text('Reset Password'), findsWidgets);
      expect(find.byType(TextFormField), findsNWidgets(3));
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pump();

      expect(find.text('Please enter the code'), findsOneWidget);
      expect(find.text('Please enter a new password'), findsOneWidget);

      verifyNever(
        () => authCubit.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWidgets('shows validation error when password is too short',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '123456');
      await tester.enterText(find.byType(TextFormField).at(1), '12345');
      await tester.enterText(find.byType(TextFormField).at(2), '12345');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pump();

      expect(find.text('Password must be at least 6 characters'), findsOneWidget);

      verifyNever(
        () => authCubit.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWidgets('shows validation error when passwords do not match',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '123456');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.enterText(find.byType(TextFormField).at(2), '654321');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);

      verifyNever(
        () => authCubit.resetPassword(
          email: any(named: 'email'),
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
        ),
      );
    });

    testWidgets('calls resetPassword when form is valid', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '123456');
      await tester.enterText(find.byType(TextFormField).at(1), '123456');
      await tester.enterText(find.byType(TextFormField).at(2), '123456');

      await tester.tap(find.widgetWithText(ElevatedButton, 'Reset Password'));
      await tester.pump();

      verify(
        () => authCubit.resetPassword(
          email: 'test@example.com',
          code: '123456',
          newPassword: '123456',
        ),
      ).called(1);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Reset failed'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.pump();

      expect(find.text('Reset failed'), findsOneWidget);
    });

    testWidgets('shows success snackbar and navigates to auth method on success',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/reset-password',
        routes: [
          GoRoute(
            path: '/reset-password',
            builder: (context, state) =>
                const ResetPasswordPage(email: 'test@example.com'),
          ),
          GoRoute(
            path: AuthRoutes.authMethod,
            builder: (context, state) => const Scaffold(
              body: Text('Auth Method Page'),
            ),
          ),
        ],
      );

      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthResetPasswordSuccess(),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          router: router,
        ),
      );

      await tester.pump();
      expect(find.text('Password reset successfully'), findsOneWidget);

      await tester.pumpAndSettle();
      expect(find.text('Auth Method Page'), findsOneWidget);
    });

    testWidgets('shows loading indicator and disables button when loading',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthLoading());
      when(() => authCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ResetPasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}