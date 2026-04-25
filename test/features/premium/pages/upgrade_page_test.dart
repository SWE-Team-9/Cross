import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/premium/presentation/pages/upgrade_page.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';

class MockRepo extends Mock implements SubscriptionRepository {}

void main() {
  setUp(() async {
    await GetIt.I.reset();

    // ✅ Register dependency used by UpgradePage
    GetIt.I.registerLazySingleton<SubscriptionRepository>(
      () => MockSubscriptionRepository(),
    );
  });

  tearDown(() async {
    await GetIt.I.reset();
  });

  testWidgets('renders upgrade page and button', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: UpgradePage(),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    // ✅ UI assertions
    expect(find.text('Upgrade to IQA3 Pro'), findsOneWidget);
  });
}
