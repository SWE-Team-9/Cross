import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/welcome_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';

void main() {
  // دالة مساعدة لبناء الـ Widget مع الـ Router المطلوب لكل تست
  Widget buildWithRouter(GoRouter router) {
    return MaterialApp.router(
      routerConfig: router,
    );
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

      await tester.pumpWidget(buildWithRouter(router));

      // التأكد من وجود النصوص الأساسية
      expect(find.text("We lead what’s next in music."), findsOneWidget);
      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);

      // التأكد من وجود الأيقونة والخلفية المرسومة
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

      await tester.pumpWidget(buildWithRouter(router));

      await tester.tap(find.text('Create an account'));
      await tester.pumpAndSettle();

      // التأكد من الوصول لصفحة التسجيل بناءً على الـ Route الجديد
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

      await tester.pumpWidget(buildWithRouter(router));

      await tester.tap(find.text('Log in'));
      await tester.pumpAndSettle();

      // التأكد من الوصول لصفحة تسجيل الدخول بناءً على الـ Route الجديد
      expect(find.text('Login Page'), findsOneWidget);
    });
  });
}
