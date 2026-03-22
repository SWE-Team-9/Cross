import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/auth/presentation/pages/reset_password_page.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.resetPassword(
          code: any(named: 'code'),
          newPassword: any(named: 'newPassword'),
          newPasswordConfirm: any(named: 'newPasswordConfirm'),
        )).thenAnswer((_) async {});
  });

  Widget buildTestableWidget({GoRouter? router}) {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: router != null
          ? MaterialApp.router(routerConfig: router)
          : const MaterialApp(
              home: ResetPasswordPage(email: 'test@example.com')),
    );
  }

  group('ResetPasswordPage', () {
    testWidgets('shows validation errors when fields are empty',
        (tester) async {
      // تكبير الشاشة لتجنب مشاكل الـ Overflow والـ Offset
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());

      final buttonFinder = find.text('Reset Password').last;
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      expect(find.text('Please enter the code'), findsOneWidget);
      expect(find.text('Please enter a new password'), findsOneWidget);
    });

    testWidgets('calls resetPassword when form is valid', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildTestableWidget());

      await tester.enterText(find.byType(TextFormField).at(0), '123456');
      await tester.enterText(find.byType(TextFormField).at(1), 'password123');
      await tester.enterText(find.byType(TextFormField).at(2), 'password123');

      final buttonFinder = find.text('Reset Password').last;
      await tester.ensureVisible(buttonFinder);
      await tester.tap(buttonFinder);
      await tester.pump();

      verify(() => authCubit.resetPassword(
            code: '123456',
            newPassword: 'password123',
            newPasswordConfirm: 'password123',
          )).called(1);
    });
  });
}
