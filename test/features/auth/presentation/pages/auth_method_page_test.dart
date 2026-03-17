import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/app/router.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/auth_method_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

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

    when(() => authCubit.checkEmail(
          email: any(named: 'email'),
        )).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({
    GoRouter? router,
    Widget? child,
  }) {
    if (router != null) {
      return BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp(
        home: child ?? const AuthMethodPage(),
      ),
    );
  }

  Future<void> prepareLargeScreen(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 2200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  group('AuthMethodPage', () {
    testWidgets('renders static content', (tester) async {
      await prepareLargeScreen(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AuthMethodPage(),
        ),
      );

      expect(find.text('Sign in or create an account'), findsOneWidget);
      expect(find.text('Continue with Facebook'), findsOneWidget);
      expect(find.text('Continue with Google'), findsOneWidget);
      expect(find.text('Continue with Apple'), findsOneWidget);
      expect(find.text('Or with email'), findsOneWidget);
      expect(find.text('Your email address or profile URL'), findsOneWidget);
      expect(find.text('CAPTCHA placeholder'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Need help?'), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      await prepareLargeScreen(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AuthMethodPage(),
        ),
      );

      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);

      verifyNever(() => authCubit.checkEmail(email: any(named: 'email')));
    });

    testWidgets('shows validation error when email is invalid', (tester) async {
      await prepareLargeScreen(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AuthMethodPage(),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'invalid-email');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);

      verifyNever(() => authCubit.checkEmail(email: any(named: 'email')));
    });

    testWidgets('calls checkEmail when email is valid', (tester) async {
      await prepareLargeScreen(tester);

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AuthMethodPage(),
        ),
      );

      await tester.enterText(find.byType(TextFormField), 'test@example.com');
      await tester.ensureVisible(find.text('Continue'));
      await tester.tap(find.text('Continue'));
      await tester.pump();

      verify(() => authCubit.checkEmail(email: 'test@example.com')).called(1);
    });

    testWidgets('navigates to login password page when email exists',
        (tester) async {
      await prepareLargeScreen(tester);

      final router = GoRouter(
        initialLocation: '/auth-method',
        routes: [
          GoRoute(
            path: '/auth-method',
            builder: (context, state) => const AuthMethodPage(),
          ),
          GoRoute(
            path: AuthRoutes.loginPassword,
            builder: (context, state) {
              final email = state.extra as String?;
              return Scaffold(
                body: Text('Login Password Page ${email ?? ''}'),
              );
            },
          ),
          GoRoute(
            path: AuthRoutes.createPassword,
            builder: (context, state) => const Scaffold(
              body: Text('Create Password Page'),
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(
              body: Text('Home Page'),
            ),
          ),
        ],
      );

      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthEmailCheckSuccess(
            exists: true,
            email: 'test@example.com',
          ),
        ]),
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Login Password Page test@example.com'), findsOneWidget);
    });

    testWidgets('navigates to create password page when email does not exist',
        (tester) async {
      await prepareLargeScreen(tester);

      final router = GoRouter(
        initialLocation: '/auth-method',
        routes: [
          GoRoute(
            path: '/auth-method',
            builder: (context, state) => const AuthMethodPage(),
          ),
          GoRoute(
            path: AuthRoutes.loginPassword,
            builder: (context, state) => const Scaffold(
              body: Text('Login Password Page'),
            ),
          ),
          GoRoute(
            path: AuthRoutes.createPassword,
            builder: (context, state) {
              final email = state.extra as String?;
              return Scaffold(
                body: Text('Create Password Page ${email ?? ''}'),
              );
            },
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(
              body: Text('Home Page'),
            ),
          ),
        ],
      );

      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthEmailCheckSuccess(
            exists: false,
            email: 'test@example.com',
          ),
        ]),
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Create Password Page test@example.com'), findsOneWidget);
    });

    testWidgets('navigates to home when state is AuthAuthenticated',
        (tester) async {
      await prepareLargeScreen(tester);

      final user = FakeUser();

      final router = GoRouter(
        initialLocation: '/auth-method',
        routes: [
          GoRoute(
            path: '/auth-method',
            builder: (context, state) => const AuthMethodPage(),
          ),
          GoRoute(
            path: AuthRoutes.loginPassword,
            builder: (context, state) => const Scaffold(
              body: Text('Login Password Page'),
            ),
          ),
          GoRoute(
            path: AuthRoutes.createPassword,
            builder: (context, state) => const Scaffold(
              body: Text('Create Password Page'),
            ),
          ),
          GoRoute(
            path: AppRoutes.home,
            builder: (context, state) => const Scaffold(
              body: Text('Home Page'),
            ),
          ),
        ],
      );

      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthAuthenticated(user),
        ]),
      );

      await tester.pumpWidget(buildTestableWidget(router: router));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      await prepareLargeScreen(tester);

      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Email check failed'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AuthMethodPage(),
        ),
      );

      await tester.pump();

      expect(find.text('Email check failed'), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is AuthLoading',
        (tester) async {
      await prepareLargeScreen(tester);

      when(() => authCubit.state).thenReturn(AuthLoading());

      await tester.pumpWidget(
        buildTestableWidget(
          child: const AuthMethodPage(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}