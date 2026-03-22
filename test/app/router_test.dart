import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/app/router.dart'
    as app_router; // استدعاء مع Alias
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

void main() {
  late MockAuthCubit authCubit;

  setUp(() {
    authCubit = MockAuthCubit();
    // إعداد الحالات الافتراضية
    when(() => authCubit.state).thenReturn(AuthInitial());
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.checkAuthStatus()).thenAnswer((_) async {});
  });

  Widget buildRouterApp() {
    return BlocProvider<AuthCubit>.value(
      value: authCubit,
      child: MaterialApp.router(
        // بما أن الـ router معرف كمتغير Global في ملفك، نستدعيه مباشرة
        routerConfig: app_router.router,
      ),
    );
  }

  group('AppRouter Tests', () {
    testWidgets('starts at splash page and calls checkAuthStatus',
        (tester) async {
      await tester.pumpWidget(buildRouterApp());

      // التحقق من وجود الـ Splash (أيقونة music_note والـ loader)
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      verify(() => authCubit.checkAuthStatus()).called(1);
    });

    testWidgets('navigates to welcome page when AuthUnauthenticated is emitted',
        (tester) async {
      whenListen(
        authCubit,
        Stream.fromIterable([AuthUnauthenticated()]),
        initialState: AuthInitial(),
      );

      await tester.pumpWidget(buildRouterApp());
      // pumpAndSettle لانتظار انتهاء الـ Navigation والـ Animations
      await tester.pumpAndSettle();

      // البحث عن النص الموجود في صفحة الـ Welcome
      expect(find.text("We lead what’s next in music."), findsOneWidget);
    });
  });
}
