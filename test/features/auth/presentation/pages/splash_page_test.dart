import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/splash_page.dart';

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

    when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({required Widget child, GoRouter? router}) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: router != null
          ? MaterialApp.router(routerConfig: router)
          : MaterialApp(home: child),
    );
  }

  group('SplashPage Tests', () {
    testWidgets('renders splash screen with icon and loader', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const SplashPage()));

      expect(find.byIcon(Icons.music_note), findsOneWidget);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      // التأكد من استدعاء فحص الحالة بمجرد فتح الصفحة (initState)
      verify(() => authCubit.checkAuthStatus()).called(1);
    });

    testWidgets('navigates to /home when state is AuthAuthenticated',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
              path: '/splash', builder: (context, state) => const SplashPage()),
          GoRoute(
              path: '/home',
              builder: (context, state) =>
                  const Scaffold(body: Text('Home Page'))),
        ],
      );

      // محاكاة انبعاث حالة "مسجل دخول"
      whenListen(
        authCubit,
        Stream.fromIterable([AuthAuthenticated(FakeUser())]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(
          buildTestableWidget(child: const SizedBox(), router: router));
      await tester.pumpAndSettle();

      expect(find.text('Home Page'), findsOneWidget);
    });

    testWidgets('navigates to /welcome when state is AuthUnauthenticated',
        (tester) async {
      final router = GoRouter(
        initialLocation: '/splash',
        routes: [
          GoRoute(
              path: '/splash', builder: (context, state) => const SplashPage()),
          GoRoute(
              path: '/welcome',
              builder: (context, state) =>
                  const Scaffold(body: Text('Welcome Page'))),
        ],
      );

      whenListen(
        authCubit,
        Stream.fromIterable([AuthUnauthenticated()]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(
          buildTestableWidget(child: const SizedBox(), router: router));
      await tester.pumpAndSettle();

      expect(find.text('Welcome Page'), findsOneWidget);
    });
  });
}
