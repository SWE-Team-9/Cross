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

  /// 🔹 PRO USER TEST
  testWidgets('PRO user sees current plan UI', (tester) async {
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
  });

  /// 🔹 CANCEL STATE TEST
  testWidgets('PRO user shows cancel/resume UI', (tester) async {
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

    // Depending on backend flags UI shows cancel/resume buttons
    expect(find.textContaining('Cancel'), findsWidgets);
    expect(find.text('Manage Billing'), findsOneWidget);
  });
}
