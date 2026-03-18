import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/forgot_password_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.forgotPassword(email: any(named: 'email')))
        .thenAnswer((_) async {});
  });

  Widget buildTestableWidget({
    required AuthCubit cubit,
    Widget? child,
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
        home: child ?? const ForgotPasswordPage(),
      ),
    );
  }

  group('ForgotPasswordPage', () {
    testWidgets('renders page content', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ForgotPasswordPage(),
        ),
      );

      // تم التحديث لتطابق الـ UI الجديد
      expect(find.text('Reset password'), findsOneWidget);
      expect(find.text('Your email address'), findsOneWidget);
      expect(find.text('Send reset link'), findsOneWidget);
      expect(find.byType(TextField), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows validation error when email is empty', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ForgotPasswordPage(),
        ),
      );

      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      // تم تحديث رسالة الخطأ لتطابق الـ UI
      expect(find.text('Please enter your email address'), findsOneWidget);
      verifyNever(() => authCubit.forgotPassword(email: any(named: 'email')));
    });

    testWidgets('calls forgotPassword when email is valid', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ForgotPasswordPage(),
        ),
      );

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.tap(find.text('Send reset link'));
      await tester.pump();

      verify(() => authCubit.forgotPassword(email: 'test@example.com'))
          .called(1);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Something went wrong'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ForgotPasswordPage(),
        ),
      );

      await tester.pump();

      expect(find.text('Something went wrong'), findsOneWidget);
    });

    testWidgets('shows success snackbar on success', (tester) async {
      when(() => authCubit.state).thenReturn(AuthInitial());
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthForgotPasswordSuccess('test@example.com'),
        ]),
      );

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ForgotPasswordPage(),
        ),
      );

      await tester.pump();

      // تم تحديث رسالة النجاح لتطابق المكتوب في الـ UI
      expect(find.text('Reset link sent to test@example.com!'), findsOneWidget);
    });

    testWidgets('shows loading indicator and disables button when loading',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthLoading());
      when(() => authCubit.stream)
          .thenAnswer((_) => const Stream<AuthState>.empty());

      await tester.pumpWidget(
        buildTestableWidget(
          cubit: authCubit,
          child: const ForgotPasswordPage(),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });
  });
}
