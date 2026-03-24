import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/register_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

void main() {
  Widget buildTestWidget() {
    final router = GoRouter(
      initialLocation: AuthRoutes.register,
      routes: [
        GoRoute(
          path: AuthRoutes.register,
          builder: (_, __) => const RegisterPage(),
        ),
        GoRoute(
          path: AuthRoutes.login,
          builder: (_, __) => const Scaffold(body: Text('login-page')),
        ),
        GoRoute(
          path: AuthRoutes.completeProfile,
          builder: (_, state) => Scaffold(
            body: Text('complete:${state.extra != null}'),
          ),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  Future<void> scrollToText(WidgetTester tester, String text) async {
    await tester.scrollUntilVisible(
      find.text(text),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();
  }

  group('RegisterPage', () {
    testWidgets('renders main register UI', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Create account'), findsOneWidget);
      expect(find.text("What's your email?"), findsOneWidget);
      expect(find.text('Create a password'), findsOneWidget);
      expect(find.text('Confirm your password'), findsOneWidget);

      await scrollToText(tester, 'Next');
      expect(find.text('Next'), findsOneWidget);

      await scrollToText(tester, 'Log in');
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('shows validation errors for empty and invalid fields',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await scrollToText(tester, 'Next');
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter a password'), findsOneWidget);

      await tester.enterText(find.byType(TextFormField).at(0), 'bad-email');
      await tester.enterText(find.byType(TextFormField).at(1), '123');
      await tester.enterText(find.byType(TextFormField).at(2), '456');

      await scrollToText(tester, 'Next');
      await tester.tap(find.text('Next'));
      await tester.pump();

      expect(find.text('Please enter a valid email'), findsOneWidget);
      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);
      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('navigates to login page from footer link', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await scrollToText(tester, 'Log in');
      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      expect(find.text('login-page'), findsOneWidget);
    });
  });
}
