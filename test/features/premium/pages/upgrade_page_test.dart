import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:bloc_test/bloc_test.dart';

import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';

class MockSubscriptionCubit extends MockCubit<Subscription?>
    implements SubscriptionCubit {}

void main() {
  late MockSubscriptionCubit mockCubit;

  setUp(() async {
    await GetIt.I.reset();

    GetIt.I.registerLazySingleton<SubscriptionRepository>(
      () => MockSubscriptionRepository(),
    );

    mockCubit = MockSubscriptionCubit();
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  /// 🔹 FREE USER TEST
  testWidgets('FREE user sees upgrade CTA', (tester) async {
    when(() => mockCubit.state).thenReturn(const Subscription(
      subscriptionType: 'FREE',
      uploadLimit: 3,
      uploadedTracks: 0,
      remainingUploads: 3,
    ));

    await tester.pumpWidget(
      BlocProvider<SubscriptionCubit>.value(
        value: mockCubit,
        child: const MaterialApp(
          home: UpgradePage(),
        ),
      ),
    );

    // ✅ FIX: avoid pumpAndSettle timeout
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Upgrade to IQA3 Pro'), findsOneWidget);
  });

  testWidgets('FREE user can switch between monthly and yearly cards',
      (tester) async {
    when(() => mockCubit.state).thenReturn(const Subscription(
      subscriptionType: 'FREE',
      uploadLimit: 3,
      uploadedTracks: 0,
      remainingUploads: 3,
    ));

    await tester.pumpWidget(
      BlocProvider<SubscriptionCubit>.value(
        value: mockCubit,
        child: const MaterialApp(
          home: UpgradePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    await tester.ensureVisible(find.text('Yearly'));
    await tester.tap(find.text('Yearly'));
    await tester.pump();

    expect(find.text('Save 50%'), findsOneWidget);

    await tester.ensureVisible(find.text('Monthly'));
    await tester.tap(find.text('Monthly'));
    await tester.pump();

    expect(find.text('EGP 175'), findsOneWidget);
  });

  testWidgets('null subscription shows loading indicator', (tester) async {
    when(() => mockCubit.state).thenReturn(null);

    await tester.pumpWidget(
      BlocProvider<SubscriptionCubit>.value(
        value: mockCubit,
        child: const MaterialApp(
          home: UpgradePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  /// 🔹 PRO USER TEST
  testWidgets('PRO user sees current plan UI', (tester) async {
    when(() => mockCubit.changePlan(any())).thenAnswer((_) async {});
    when(() => mockCubit.cancel()).thenAnswer((_) async {});
    when(() => mockCubit.state).thenReturn(const Subscription(
      subscriptionType: 'PRO',
      uploadLimit: 100,
      uploadedTracks: 4,
      remainingUploads: 96,
    ));

    await tester.pumpWidget(
      BlocProvider<SubscriptionCubit>.value(
        value: mockCubit,
        child: const MaterialApp(
          home: UpgradePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('Current Plan'), findsOneWidget);
    expect(find.textContaining('IQA3 Pro'), findsWidgets);
    expect(find.text('Manage Billing'), findsOneWidget);

    await tester.ensureVisible(find.text('Upgrade to GO+'));
    await tester.tap(find.text('Upgrade to GO+'));
    await tester.pump();

    verify(() => mockCubit.changePlan('GO_PLUS')).called(1);

    await tester.ensureVisible(find.text('Cancel Subscription'));
    await tester.tap(find.text('Cancel Subscription'));
    await tester.pump();

    verify(() => mockCubit.cancel()).called(1);
  });

  /// 🔹 CANCEL STATE TEST
  testWidgets('PRO user shows cancel/resume UI', (tester) async {
    when(() => mockCubit.resume()).thenAnswer((_) async {});
    when(() => mockCubit.state).thenReturn(const Subscription(
      subscriptionType: 'PRO',
      uploadLimit: 100,
      uploadedTracks: 4,
      remainingUploads: 96,
      cancelAtPeriodEnd: true,
    ));

    await tester.pumpWidget(
      BlocProvider<SubscriptionCubit>.value(
        value: mockCubit,
        child: const MaterialApp(
          home: UpgradePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('Resume Subscription'), findsOneWidget);
    expect(find.text('Manage Billing'), findsOneWidget);

    await tester.ensureVisible(find.text('Resume Subscription'));
    await tester.tap(find.text('Resume Subscription'));
    await tester.pump();

    verify(() => mockCubit.resume()).called(1);
  });

  testWidgets('GO_PLUS user can downgrade to Pro', (tester) async {
    when(() => mockCubit.changePlan(any())).thenAnswer((_) async {});
    when(() => mockCubit.cancel()).thenAnswer((_) async {});
    when(() => mockCubit.state).thenReturn(const Subscription(
      subscriptionType: 'GO_PLUS',
      uploadLimit: 1000,
      uploadedTracks: 4,
      remainingUploads: 996,
    ));

    await tester.pumpWidget(
      BlocProvider<SubscriptionCubit>.value(
        value: mockCubit,
        child: const MaterialApp(
          home: UpgradePage(),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('IQA3 GO+'), findsWidgets);

    await tester.ensureVisible(find.text('Downgrade to Pro'));
    await tester.tap(find.text('Downgrade to Pro'));
    await tester.pump();

    verify(() => mockCubit.changePlan('PRO')).called(1);
  });
}
