import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/app/router.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/complete_profile_page.dart';

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
      () => authCubit.completeProfile(
        displayName: any(named: 'displayName'),
        birthMonth: any(named: 'birthMonth'),
        birthDay: any(named: 'birthDay'),
        birthYear: any(named: 'birthYear'),
        gender: any(named: 'gender'),
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

  Future<void> selectDropdownItem(
    WidgetTester tester,
    String hintText,
    String itemText,
  ) async {
    final dropdown = find.widgetWithText(
      DropdownButtonFormField<String>,
      hintText,
    );

    expect(dropdown, findsOneWidget);

    await tester.ensureVisible(dropdown);
    await tester.tap(dropdown);
    await tester.pumpAndSettle();

    final item = find.text(itemText).first;
    expect(item, findsWidgets);

    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  group('CompleteProfilePage', () {
    testWidgets('renders static texts and fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CompleteProfilePage(),
        ),
      );

      expect(find.text('Tell us more about you'), findsOneWidget);
      expect(find.text('Display name'), findsOneWidget);
      expect(find.text('Date of birth (required)'), findsOneWidget);
      expect(find.text('Gender (required)'), findsOneWidget);
      expect(find.text('Continue'), findsOneWidget);
      expect(find.byType(DropdownButtonFormField<String>), findsNWidgets(4));
    });

    testWidgets('shows snackbar when fields are incomplete', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CompleteProfilePage(),
        ),
      );

      await tester.tap(find.text('Continue'));
      await tester.pump();

      expect(find.text('Please complete all fields'), findsOneWidget);

      verifyNever(
        () => authCubit.completeProfile(
          displayName: any(named: 'displayName'),
          birthMonth: any(named: 'birthMonth'),
          birthDay: any(named: 'birthDay'),
          birthYear: any(named: 'birthYear'),
          gender: any(named: 'gender'),
        ),
      );
    });

    testWidgets('calls completeProfile when all fields are filled',
        (tester) async {
      tester.view.physicalSize = const Size(1400, 2200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      final currentYear = DateTime.now().year.toString();

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CompleteProfilePage(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'Muslim');

      await selectDropdownItem(tester, 'Month', 'May');
      await selectDropdownItem(tester, 'Day', '15');
      await selectDropdownItem(tester, 'Year', currentYear);
      await selectDropdownItem(tester, 'Gender (required)', 'Male');

      await tester.tap(find.text('Continue'));
      await tester.pump();

      verify(
        () => authCubit.completeProfile(
          displayName: 'Muslim',
          birthMonth: 5,
          birthDay: 15,
          birthYear: int.parse(currentYear),
          gender: 'Male',
        ),
      ).called(1);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Profile completion failed'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const CompleteProfilePage(),
        ),
      );

      await tester.pump();

      expect(find.text('Profile completion failed'), findsOneWidget);
    });

    testWidgets('navigates to home when state is AuthProfileCompleted',
        (tester) async {
      final user = FakeUser();

      final router = GoRouter(
        initialLocation: '/complete-profile',
        routes: [
          GoRoute(
            path: '/complete-profile',
            builder: (context, state) => const CompleteProfilePage(),
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
          AuthProfileCompleted(user),
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

    testWidgets('navigates to home when state is AuthAuthenticated',
        (tester) async {
      final user = FakeUser();

      final router = GoRouter(
        initialLocation: '/complete-profile',
        routes: [
          GoRoute(
            path: '/complete-profile',
            builder: (context, state) => const CompleteProfilePage(),
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
          child: const CompleteProfilePage(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });
  });
}
