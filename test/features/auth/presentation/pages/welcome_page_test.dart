import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/welcome_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  Widget buildWithRouter(GoRouter router, AuthCubit authCubit) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  MockAuthCubit buildAuthCubit() {
    final authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.continueWithGoogle()).thenAnswer((_) async {});
    return authCubit;
  }

  group('WelcomePage Tests', () {
    testWidgets('renders welcome content, illustration and buttons',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomePage(),
          ),
        ],
      );

      await tester.pumpWidget(buildWithRouter(router, buildAuthCubit()));

      expect(find.text("We lead what’s next in music."), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('navigates to register page when tapping Create an account',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomePage(),
          ),
          GoRoute(
            path: AuthRoutes.register,
            builder: (context, state) =>
                const Scaffold(body: Text('Register Page')),
          ),
        ],
      );

      await tester.pumpWidget(buildWithRouter(router, buildAuthCubit()));

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      expect(find.text('Register Page'), findsOneWidget);
    });

    testWidgets('navigates to login page when tapping Log in', (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomePage(),
          ),
          GoRoute(
            path: AuthRoutes.login,
            builder: (context, state) =>
                const Scaffold(body: Text('Login Page')),
          ),
        ],
      );

      await tester.pumpWidget(buildWithRouter(router, buildAuthCubit()));

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
