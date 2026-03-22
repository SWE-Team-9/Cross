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
    when(() => authCubit.remainingResendSeconds).thenReturn(60);
    when(() => authCubit.sendEmailVerification(email: any(named: 'email')))
        .thenAnswer((_) async {});
  });

  testWidgets('renders initial UI elements correctly and shows timer',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const VerifyEmailPage(email: 'test@example.com'),
      ),
    ));

    expect(find.text('Check Your Email'), findsOneWidget);
    expect(find.text('test@example.com'), findsOneWidget);

    // استخدام textContaining لأن الثواني قد تنقص لـ 59 قبل الفحص
    expect(find.textContaining('Resend link in'), findsOneWidget);
  });
}
