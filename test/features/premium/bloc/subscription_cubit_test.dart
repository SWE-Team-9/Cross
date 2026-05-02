import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:soundcloud_clone/features/premium/presentation/bloc/subscription_cubit.dart';
import 'package:soundcloud_clone/features/premium/domain/entities/subscription.dart';
import 'package:soundcloud_clone/features/premium/domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository extends Mock
    implements SubscriptionRepository {}

void main() {
  late MockSubscriptionRepository repo;
  late SubscriptionCubit cubit;

  setUp(() {
    repo = MockSubscriptionRepository();
    cubit = SubscriptionCubit(repo);
  });

  final freeSub = const Subscription(
    subscriptionType: 'FREE',
    uploadLimit: 3,
    uploadedTracks: 3,
    remainingUploads: 0,
  );

  blocTest<SubscriptionCubit, Subscription?>(
    'loads FREE subscription on init',
    build: () {
      when(() => repo.getMySubscription()).thenAnswer((_) async => freeSub);
      return cubit;
    },
    act: (cubit) => cubit.loadSubscription(),
    expect: () => [freeSub],
  );

  blocTest<SubscriptionCubit, Subscription?>(
    'upgrade returns checkout URL (no state emit)',
    build: () {
      when(() => repo.createCheckout('PRO'))
          .thenAnswer((_) async => 'https://checkout.url');
      return cubit;
    },
    act: (cubit) => cubit.upgrade('PRO'),
    expect: () => [], // ✅ FIX
  );
  blocTest<SubscriptionCubit, Subscription?>(
    'refreshAfterPayment reloads subscription',
    build: () {
      when(() => repo.getMySubscription()).thenAnswer((_) async => freeSub);
      return cubit;
    },
    act: (cubit) => cubit.refreshAfterPayment(),
    expect: () => [freeSub],
  );

  blocTest<SubscriptionCubit, Subscription?>(
    'cancel resume and changePlan reload subscription state',
    build: () {
      when(() => repo.cancelSubscription()).thenAnswer((_) async {});
      when(() => repo.resumeSubscription()).thenAnswer((_) async {});
      when(() => repo.changePlan('PRO')).thenAnswer((_) async {});
      when(() => repo.getMySubscription()).thenAnswer((_) async => freeSub);
      return cubit;
    },
    act: (cubit) async {
      await cubit.cancel();
      await cubit.resume();
      await cubit.changePlan('PRO');
    },
    expect: () => [freeSub],
  );

  test('openBillingPortal delegates to repository', () async {
    when(() => repo.openPortal()).thenAnswer((_) async => 'https://portal');

    expect(await cubit.openBillingPortal(), 'https://portal');
  });
}
