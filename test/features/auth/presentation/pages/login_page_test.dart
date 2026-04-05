import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/login_page.dart';
import 'package:soundcloud_clone/features/auth/presentation/routes/auth_routes.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;
  Future<String> defaultCaptchaProvider(BuildContext _) async => 'test-captcha';

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.login(
          email: any(named: 'email'),
          password: any(named: 'password'),
          rememberMe: any(named: 'rememberMe'),
          captchaToken: any(named: 'captchaToken'),
        )).thenAnswer((_) async {});
  });

  Widget buildTestWidget({
    LoginCaptchaTokenProvider? captchaProvider,
  }) {
    final router = GoRouter(
      initialLocation: AuthRoutes.login,
      routes: [
        GoRoute(
          path: AuthRoutes.login,
          builder: (_, __) => BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: LoginPage(
              captchaTokenProvider: captchaProvider ?? defaultCaptchaProvider,
            ),
          ),
        ),
        GoRoute(
          path: AuthRoutes.forgotPassword,
          builder: (_, __) => const Scaffold(body: Text('forgot-page')),
        ),
        GoRoute(
          path: AuthRoutes.verifyEmail,
          builder: (_, state) => Scaffold(
            body: Text('verify:${state.extra}'),
          ),
        ),
        GoRoute(
          path: '/home',
          builder: (_, __) => const Scaffold(body: Text('home-page')),
        ),
      ],
    );

    return MaterialApp.router(routerConfig: router);
  }

  group('LoginPage', () {
    testWidgets('renders main login UI', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      expect(find.text('Log in to your account'), findsOneWidget);
      expect(find.text('Email address'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Forgot password?'), findsOneWidget);
      expect(find.text('Log in'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('Please enter your email'), findsOneWidget);
      expect(find.text('Please enter your password'), findsOneWidget);

      verifyNever(() => authCubit.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
            captchaToken: any(named: 'captchaToken'),
          ));
    });

    testWidgets('toggles remember me checkbox', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      Checkbox checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isFalse);

      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      checkbox = tester.widget(find.byType(Checkbox));
      expect(checkbox.value, isTrue);
    });

    testWidgets('toggles password visibility', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      EditableText editableText =
          tester.widget<EditableText>(find.byType(EditableText).at(1));
      expect(editableText.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      editableText =
          tester.widget<EditableText>(find.byType(EditableText).at(1));
      expect(editableText.obscureText, isFalse);
    });

    testWidgets('navigates to forgot password page', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.tap(find.text('Forgot password?'));
      await tester.pumpAndSettle();

      expect(find.text('forgot-page'), findsOneWidget);
    });

    testWidgets('shows snackbar when AuthError is emitted', (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([
          AuthError('Wrong Email or Password'),
        ]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Wrong Email or Password'), findsOneWidget);
    });

    testWidgets('shows Verify Now action for not verified error',
        (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([
          AuthError(
            'Please verify your email before logging in.',
            isNotVerified: true,
          ),
        ]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('Verify Now'), findsOneWidget);

      await tester.enterText(
          find.byType(TextFormField).first, 'ali@example.com');
      await tester.tap(find.text('Verify Now'));
      await tester.pumpAndSettle();

      expect(find.text('verify:ali@example.com'), findsOneWidget);
    });

    testWidgets('navigates to home on AuthAuthenticated', (tester) async {
      whenListen(
        authCubit,
        Stream<AuthState>.fromIterable([
          AuthAuthenticated(
            const User(
              id: '1',
              email: 'ali@example.com',
              handle: 'ali',
            ),
          ),
        ]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildTestWidget());
      await tester.pumpAndSettle();

      expect(find.text('home-page'), findsOneWidget);
    });

    testWidgets('does not submit when password is empty', (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'valid@example.com',
      );

      await tester.tap(find.text('Log in'));
      await tester.pump();

      expect(find.text('Please enter your password'), findsOneWidget);
      verifyNever(() => authCubit.login(
            email: any(named: 'email'),
            password: any(named: 'password'),
            rememberMe: any(named: 'rememberMe'),
            captchaToken: any(named: 'captchaToken'),
          ));
    });

    testWidgets('submits login with captcha token when form is valid',
        (tester) async {
      await tester.pumpWidget(buildTestWidget());
      await tester.pump();

      await tester.enterText(
        find.byType(TextFormField).at(0),
        'valid@example.com',
      );
      await tester.enterText(
        find.byType(TextFormField).at(1),
        'ValidPass123!',
      );
      await tester.tap(find.byType(Checkbox));
      await tester.pump();

      await tester.tap(find.text('Log in'));
      await tester.pump();

      verify(() => authCubit.login(
            email: 'valid@example.com',
            password: 'ValidPass123!',
            rememberMe: true,
            captchaToken: 'test-captcha',
          )).called(1);
    });
  });
}
