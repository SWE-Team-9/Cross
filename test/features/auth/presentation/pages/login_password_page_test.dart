import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/app/router.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/login_password_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class FakeUser extends Fake implements User {}

void main() {
  late MockAuthCubit authCubit;

  setUpAll(() {
    registerFallbackValue(FakeUser());
  });

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.login(
        email: any(named: 'email'),
        password: any(named: 'password'))).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({
    required AuthCubit cubit,
    required Widget child,
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
        home: child,
      ),
    );
  }

  group('LoginPasswordPage', () {
    testWidgets('renders static texts and email', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const LoginPasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Your email address'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Need help?'), findsOneWidget);
      expect(find.text('Enter your password'), findsOneWidget);
    });

    testWidgets('shows snackbar when password is empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const LoginPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
      verifyNever(() => authCubit.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
          ));
    });

    testWidgets('calls login when password is entered', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const LoginPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextField), '123456');
      await tester.tap(find.text('Continue'));
      await tester.pump();

      verify(() => authCubit.login(
            email: 'test@example.com',
            password: '123456',
          )).called(1);
    });

    testWidgets('toggles password visibility when suffix icon is tapped',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const LoginPasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
      expect(find.byIcon(Icons.visibility_outlined), findsNothing);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Invalid credentials'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const LoginPasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.pump();

      expect(find.text('Invalid credentials'), findsOneWidget);
    });

    testWidgets('navigates to home when state is AuthAuthenticated',
        (tester) async {
      final user = FakeUser();

      final router = GoRouter(
        initialLocation: '/login-password',
        routes: [
          GoRoute(
            path: '/login-password',
            builder: (context, state) =>
                const LoginPasswordPage(email: 'test@example.com'),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(
              body: Text('Home Page'),
            ),
          ),
        ],
      );

      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthAuthenticated(user),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const SizedBox(),
          router: router,
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is AuthLoading',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthLoading());
      when(() => authCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const LoginPasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
