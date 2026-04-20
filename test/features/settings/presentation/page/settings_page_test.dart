import 'package:bloc_test/bloc_test.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/core/di/injector.dart';
import 'package:soundcloud_clone/features/auth/domain/entities/user.dart'
    as auth_domain;
import 'package:soundcloud_clone/features/auth/presentation/bloc/auth_cubit.dart';
import 'package:soundcloud_clone/features/settings/presentation/page/settings_page.dart';
import 'package:soundcloud_clone/features/social/data/repositories/social_repo.dart';

class MockAuthCubit extends MockCubit<AuthState> implements AuthCubit {}

class MockSocialRepo extends Mock implements SocialRepo {}

class MockDio extends Mock implements Dio {}

void main() {
  late MockAuthCubit authCubit;
  late MockSocialRepo socialRepo;
  late AuthState currentState;

  const user = auth_domain.User(
    id: 'u1',
    email: 'ali@test.com',
    handle: 'ali',
  );

  setUp(() async {
    await getIt.reset();
    authCubit = MockAuthCubit();
    socialRepo = MockSocialRepo();
    currentState = AuthAuthenticated(user);

    when(() => authCubit.state).thenAnswer((_) => currentState);
    when(() => authCubit.stream)
        .thenAnswer((_) => const Stream<AuthState>.empty());
    when(() => authCubit.logout()).thenAnswer((_) async {});
    when(
      () => authCubit.requestEmailChange(
        newEmail: any(named: 'newEmail'),
        currentPassword: any(named: 'currentPassword'),
      ),
    ).thenAnswer((_) async {});
    when(() => authCubit.emailChangeCooldownRemainingSeconds).thenReturn(0);

    when(() => socialRepo.dio).thenReturn(MockDio());
    when(() => socialRepo.getBlockedUsers(1, limit: 20))
        .thenAnswer((_) async => const []);

    getIt.registerLazySingleton<SocialRepo>(() => socialRepo);
  });

  tearDown(() async {
    await getIt.reset();
  });

  Widget buildPage() {
    return MaterialApp(
      home: BlocProvider<AuthCubit>.value(
        value: authCubit,
        child: const SettingsPage(),
      ),
    );
  }

  group('SettingsPage', () {
    testWidgets('renders sections and authenticated profile info',
        (tester) async {
      await tester.pumpWidget(buildPage());

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('ACCOUNT'), findsOneWidget);
      expect(find.text('PRIVACY'), findsOneWidget);
      expect(find.text('@ali'), findsOneWidget);
      expect(find.text('Blocked accounts'), findsOneWidget);
    });

    testWidgets('opens blocked accounts page', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Blocked accounts'));
      await tester.pumpAndSettle();

      expect(find.text('Blocked Accounts'), findsOneWidget);
      expect(find.text('No blocked accounts'), findsOneWidget);
    });

    testWidgets('shows change password dialog', (tester) async {
      await tester.pumpWidget(buildPage());

      await tester.tap(find.text('Change password'));
      await tester.pumpAndSettle();

      expect(find.text('This feature is coming soon.'), findsOneWidget);
      expect(find.text('This feature is coming soon.'), findsOneWidget);

      await tester.tap(find.text('OK'));
      await tester.pumpAndSettle();
      expect(find.text('This feature is coming soon.'), findsNothing);
    });

    testWidgets('confirms sign out and calls logout', (tester) async {
      await tester.pumpWidget(buildPage());
      await tester.drag(find.byType(ListView), const Offset(0, -1500));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign out'));
      await tester.pumpAndSettle();
      expect(find.text('Are you sure you want to sign out?'), findsOneWidget);

      await tester.tap(find.text('Sign out').last);
      await tester.pumpAndSettle();

      verify(() => authCubit.logout()).called(1);
    });

    testWidgets('change email dialog validates cooldown and failure states',
        (tester) async {
      when(() => authCubit.emailChangeCooldownRemainingSeconds).thenReturn(30);

      await tester.pumpWidget(buildPage());
      await tester.tap(find.text('Change email'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'password123',
      );

      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Wait 30 seconds before resending.'),
          findsOneWidget);

      when(() => authCubit.emailChangeCooldownRemainingSeconds).thenReturn(0);
      when(
        () => authCubit.requestEmailChange(
          newEmail: any(named: 'newEmail'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async {
        currentState = AuthEmailChangeFailure(
          user: user,
          message: 'Invalid password',
        );
      });

      await tester.tap(find.text('Send link'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid password'), findsOneWidget);
    });

    testWidgets('change email success shows snackbar', (tester) async {
      when(
        () => authCubit.requestEmailChange(
          newEmail: any(named: 'newEmail'),
          currentPassword: any(named: 'currentPassword'),
        ),
      ).thenAnswer((_) async {
        currentState = AuthEmailChangeRequested(
          user: user,
          newEmail: 'new@example.com',
        );
      });

      await tester.pumpWidget(buildPage());
      await tester.tap(find.text('Change email'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'New email'),
        'new@example.com',
      );
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Current password'),
        'password123',
      );

      await tester.tap(find.text('Send link'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Confirmation sent to new@example.com'), findsOneWidget);
    });
  });
}
