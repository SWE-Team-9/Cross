import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/welcome_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

void main() {
  Widget buildWithRouter(GoRouter router) {
    return MaterialApp.router(
      routerConfig: router,
    );
  }

  group('WelcomePage', () {
    testWidgets('renders welcome content and buttons', (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomePage(),
          ),
          GoRoute(
            path: AuthRoutes.authMethod,
            builder: (context, state) => const Scaffold(
              body: Text('Auth Method Page'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildWithRouter(router));

      expect(find.text("We lead what’s next in music."), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.byIcon(Icons.cloud), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);
    });

    testWidgets('navigates to auth method when tapping Create an account',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomePage(),
          ),
          GoRoute(
            path: AuthRoutes.authMethod,
            builder: (context, state) => const Scaffold(
              body: Text('Auth Method Page'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildWithRouter(router));

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      expect(find.text('Auth Method Page'), findsOneWidget);
    });

    testWidgets('navigates to auth method when tapping Log in', (tester) async {
      final router = GoRouter(
        initialLocation: '/welcome',
        routes: [
          GoRoute(
            path: '/welcome',
            builder: (context, state) => const WelcomePage(),
          ),
          GoRoute(
            path: AuthRoutes.authMethod,
            builder: (context, state) => const Scaffold(
              body: Text('Auth Method Page'),
            ),
          ),
        ],
      );

      await tester.pumpWidget(buildWithRouter(router));

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('Auth Method Page'), findsOneWidget);
    });
  });
}
