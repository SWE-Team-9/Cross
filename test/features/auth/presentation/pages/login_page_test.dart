import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/login_page.dart';

// Mocks
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

    // Mock لدالة الـ login الجديدة مع الـ captchaToken
    when(() => authCubit.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          captchaToken: any(named: 'captchaToken'),
        )).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({required Widget child, GoRouter? router}) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: router != null
          ? MaterialApp.router(routerConfig: router)
          : MaterialApp(home: child),
    );
  }

  group('LoginPage UI Tests', () {
    testWidgets('renders all essential fields and buttons', (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const LoginPage()));

      expect(find.text('Log in to your account'), findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Enter your email'),
          findsOneWidget);
      expect(find.widgetWithText(TextFormField, 'Enter your password'),
          findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('toggles password visibility when eye icon is tapped',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget(child: const LoginPage()));

      final passwordField =
          find.widgetWithText(TextFormField, 'Enter your password');
      expect(
          tester
              .widget<TextField>(find.descendant(
                of: passwordField,
                matching: find.byType(TextField),
              ))
              .obscureText,
          isTrue);
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(
          tester
              .widget<TextField>(find.descendant(
                of: passwordField,
                matching: find.byType(TextField),
              ))
              .obscureText,
          isFalse);
    });
    group('LoginPage Logic & Navigation', () {
      testWidgets(
          'shows Verify Now action in SnackBar when email is not verified',
          (tester) async {
        // نرسل حالة خطأ مع flag التفعيل
        whenListen(
          authCubit,
          Stream.fromIterable(
              [AuthError('Please verify your email', isNotVerified: true)]),
          initialState: AuthInitial(),
        );

        await tester.pumpWidget(buildTestableWidget(child: const LoginPage()));
        await tester.pump(); // لاستقبال الحالة من الـ stream

        expect(find.text('Verify Now'), findsOneWidget);
        expect(find.text('Please verify your email'), findsOneWidget);
      });

      testWidgets('navigates to home when AuthAuthenticated is emitted',
          (tester) async {
        final router = GoRouter(
          initialLocation: '/login',
          routes: [
            GoRoute(
                path: '/login', builder: (context, state) => const LoginPage()),
            GoRoute(
                path: '/home',
                builder: (context, state) =>
                    const Scaffold(body: Text('Home Page'))),
          ],
        );

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
    });

    testWidgets('shows loading state when AuthLoading is active',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthLoading());

      await tester.pumpWidget(buildTestableWidget(child: const LoginPage()));

      // الـ AuthButton داخله CircularProgressIndicator لما يكون isLoading true
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
