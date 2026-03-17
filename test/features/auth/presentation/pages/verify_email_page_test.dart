import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/verify_email_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => authCubit.verifyEmail(
          email: any(named: 'email'),
          code: any(named: 'code'),
        )).thenAnswer((_) async {});

    when(() => authCubit.sendEmailVerification(
          email: any(named: 'email'),
        )).thenAnswer((_) async {});
  });

  Widget buildTestableWidget() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: const MaterialApp(
        home: VerifyEmailPage(email: 'test@example.com'),
      ),
    );
  }

  group('VerifyEmailPage', () {
    testWidgets('renders page content', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      expect(find.text('Verify Email'), findsWidgets);
      expect(find.text('Verify email: test@example.com'), findsOneWidget);
      expect(find.text('Verification Code'), findsOneWidget);
      expect(find.text('Resend Code'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('shows validation error when code is empty', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Email'));
      await tester.pump();

      expect(find.text('Please enter the code'), findsOneWidget);

      verifyNever(() => authCubit.verifyEmail(
            email: any(named: 'email'),
            code: any(named: 'code'),
          ));
    });

    testWidgets('calls verifyEmail when code is valid', (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextFormField), '123456');
      await tester.tap(find.widgetWithText(ElevatedButton, 'Verify Email'));
      await tester.pump();

      verify(() => authCubit.verifyEmail(
            email: 'test@example.com',
            code: '123456',
          )).called(1);
    });

    testWidgets('calls sendEmailVerification when tapping resend code',
        (tester) async {
      await tester.pumpWidget(buildTestableWidget());

      await tester.tap(find.text('Resend Code'));
      await tester.pump();

      verify(() => authCubit.sendEmailVerification(
            email: 'test@example.com',
          )).called(1);
    });

    testWidgets('shows snackbar when state is AuthEmailVerified',
        (tester) async {
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthEmailVerified(),
        ]),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Email verified successfully'), findsOneWidget);
    });

    testWidgets('shows snackbar when state is AuthVerificationEmailSent',
        (tester) async {
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthVerificationEmailSent('test@example.com'),
        ]),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Verification email sent again'), findsOneWidget);
    });

    testWidgets('shows snackbar when state is AuthError', (tester) async {
      when(() => authCubit.stream).thenAnswer(
        (_) => Stream<AuthState>.fromIterable([
          AuthError('Verification failed'),
        ]),
      );

      await tester.pumpWidget(buildTestableWidget());
      await tester.pump();

      expect(find.text('Verification failed'), findsOneWidget);
    });

    testWidgets('shows loading indicator and disables actions when loading',
        (tester) async {
      when(() => authCubit.state).thenReturn(AuthLoading());

      await tester.pumpWidget(buildTestableWidget());

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      final verifyButton =
          tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(verifyButton.onPressed, isNull);

      final resendButton = tester.widget<TextButton>(find.byType(TextButton));
      expect(resendButton.onPressed, isNull);
    });
  });
}