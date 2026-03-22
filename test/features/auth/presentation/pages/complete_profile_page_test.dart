import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/complete_profile_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  final Map<String, String> tRegistrationData = {
    'email': 'test@example.com',
    'password': 'password123',
    'passwordConfirm': 'password123',
    'captchaToken': 'mock_token',
  };

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());

    when(() => authCubit.register(
          email: any(named: 'email'),
          password: any(named: 'password'),
          passwordConfirm: any(named: 'passwordConfirm'),
          displayName: any(named: 'displayName'),
          dateOfBirth: any(named: 'dateOfBirth'),
          gender: any(named: 'gender'),
          captchaToken: any(named: 'captchaToken'),
        )).thenAnswer((_) async {});
  });

  Future<void> selectItem(
      WidgetTester tester, String hint, String itemText) async {
    final dropdown = find.widgetWithText(DropdownButtonFormField<String>, hint);
    await tester.ensureVisible(dropdown);
    // استخدمنا warnIfMissed: false لتجاوز أي مشاكل في الـ HitTest
    await tester.tap(dropdown, warnIfMissed: false);
    await tester.pumpAndSettle();

    final item = find.text(itemText).last;
    await tester.ensureVisible(item);
    await tester.tap(item, warnIfMissed: false);
    await tester.pumpAndSettle();
  }

  group('CompleteProfilePage Tests', () {
    testWidgets('calls register when all fields are filled correctly',
        (tester) async {
      // الحل الجذري والنهائي لمشكلة الـ Overflow
      await tester.binding.setSurfaceSize(const Size(3000, 3000));
      tester.view.physicalSize = const Size(3000, 3000);
      tester.view.devicePixelRatio = 1.0;

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: CompleteProfilePage(registrationData: tRegistrationData),
          ),
        ),
      ));

      await tester.pumpAndSettle();

      // 1. إدخال النص
      await tester.enterText(find.byType(TextField), 'John Doe');
      await tester.pumpAndSettle();

      // 2. الحل الجذري لمشكلة Unfinished batch edits (إغلاق الكيبورد تماماً)
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      // 3. اختيار التواريخ
      await selectItem(tester, 'Month', 'January');
      await selectItem(tester, 'Day', '1');
      await selectItem(tester, 'Year', '2000');
      await selectItem(tester, 'Gender (required)', 'Male');

      final button = find.text('Continue');
      await tester.ensureVisible(button);
      await tester.tap(button, warnIfMissed: false);
      await tester.pumpAndSettle();

      verify(() => authCubit.register(
            email: tRegistrationData['email']!,
            password: tRegistrationData['password']!,
            passwordConfirm: tRegistrationData['passwordConfirm']!,
            displayName: 'John Doe',
            dateOfBirth: '2000-01-01',
            gender: 'MALE',
            captchaToken: tRegistrationData['captchaToken']!,
          )).called(1);

      // إعادة حجم الشاشة لطبيعته بعد التيست
      await tester.binding.setSurfaceSize(null);
    });

    testWidgets('shows snackbar when registration fails', (tester) async {
      await tester.binding.setSurfaceSize(const Size(3000, 3000));

      whenListen(
        authCubit,
        Stream.fromIterable([AuthError('Registration failed')]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(MaterialApp(
        home: Scaffold(
          body: BlocProvider<AuthCubit>.value(
            value: authCubit,
            child: CompleteProfilePage(registrationData: tRegistrationData),
          ),
        ),
      ));

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      // تنظيف الـ Focus احتياطياً
      FocusManager.instance.primaryFocus?.unfocus();
      await tester.pumpAndSettle();

      expect(find.text('Registration failed'), findsOneWidget);

      await tester.binding.setSurfaceSize(null);
    });
  });
}
