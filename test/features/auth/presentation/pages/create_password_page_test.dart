import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/create_password_page.dart';
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
    when(
      () => authCubit.register(
        email: any(named: 'email'),
        password: any(named: 'password'),
      ),
    ).thenAnswer((_) async {});
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

  group('CreatePasswordPage', () {
    testWidgets('renders static texts and email', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.text('Create an account'), findsOneWidget);
      expect(find.text('Your email address'), findsOneWidget);
      expect(find.text('test@example.com'), findsOneWidget);
      expect(
        find.text('Choose a password (min. 8 characters)'),
        findsOneWidget,
      );
      expect(find.text('Confirm password'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.text('Need help?'), findsOneWidget);
    });

    testWidgets('shows validation errors when fields are empty',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Please enter a password'), findsOneWidget);
      expect(find.text('Please confirm your password'), findsOneWidget);

      verifyNever(
        () => authCubit.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets(
        'shows validation error when password is less than 8 characters',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '1234567');
      await tester.enterText(find.byType(TextFormField).at(1), '1234567');

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(
          find.text('Password must be at least 8 characters'), findsOneWidget);

      verifyNever(
        () => authCubit.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('shows validation error when passwords do not match',
        (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '12345678');
      await tester.enterText(find.byType(TextFormField).at(1), '87654321');

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Passwords do not match'), findsOneWidget);

      verifyNever(
        () => authCubit.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
        ),
      );
    });

    testWidgets('calls register when form is valid', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.enterText(find.byType(TextFormField).at(0), '12345678');
      await tester.enterText(find.byType(TextFormField).at(1), '12345678');

      await tester.tap(find.text('Continue'));
      await tester.pump();

      verify(
        () => authCubit.register(
          email: 'test@example.com',
          password: '12345678',
        ),
      ).called(1);
    });

    testWidgets('toggles first password visibility', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.byIcon(Icons.visibility_outlined), findsNWidgets(2));
      expect(find.byIcon(Icons.visibility_off_outlined), findsNothing);

      await tester.tap(find.byIcon(Icons.visibility_outlined).at(0));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('toggles confirm password visibility', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.tap(find.byIcon(Icons.visibility_outlined).at(1));
      await tester.pump();

      expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Registration failed'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      await tester.pump();

      expect(find.text('Registration failed'), findsOneWidget);
    });

    testWidgets(
        'navigates to complete profile when state is AuthRegisterSuccess',
        (tester) async {
      final user = FakeUser();

      final router = GoRouter(
        initialLocation: '/create-password',
        routes: [
          GoRoute(
            path: '/create-password',
            builder: (context, state) =>
                const CreatePasswordPage(email: 'test@example.com'),
          ),
          GoRoute(
            path: AuthRoutes.completeProfile,
            builder: (context, state) => const Scaffold(
              body: Text('Complete Profile Page'),
            ),
          ),
        ],
      );

      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthRegisterSuccess(user),
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

      expect(find.text('Complete Profile Page'), findsOneWidget);
    });

    testWidgets('shows loading indicator when state is AuthLoading',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthLoading());
      when(() => authCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CreatePasswordPage(email: 'test@example.com'),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
