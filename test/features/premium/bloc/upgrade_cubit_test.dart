import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:soundcloud_clone/features/premium/presentation/bloc/upgrade_cubit.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/upgrade_state.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  late UpgradeCubit cubit;
  late MockSubscriptionRepository repo;

  setUp(() {
    repo = MockSubscriptionRepository();
    cubit = UpgradeCubit(repo);
  });

  blocTest<UpgradeCubit, UpgradeState>(
    'selectPlan updates selected plan',
    build: () => cubit,
    act: (cubit) => cubit.selectPlan('PRO'),
    expect: () => [
      const UpgradeState(selectedPlan: 'PRO'),
    ],
  );

  blocTest<UpgradeCubit, UpgradeState>(
    'subscribe emits loading then success with checkout URL',
    build: () {
      when(() => repo.createCheckout('PRO'))
          .thenAnswer((_) async => 'https://checkout.url');
      return cubit;
    },
    seed: () => const UpgradeState(selectedPlan: 'PRO'),
    act: (cubit) => cubit.subscribe(),
    expect: () => [
      const UpgradeState(
        selectedPlan: 'PRO',
        status: UpgradeStatus.loading,
      ),
      const UpgradeState(
        selectedPlan: 'PRO',
        status: UpgradeStatus.success,
        checkoutUrl: 'https://checkout.url', // ✅ important
      ),
    ],
  );
}
