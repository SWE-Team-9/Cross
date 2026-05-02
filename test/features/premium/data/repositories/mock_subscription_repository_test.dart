import 'package:flutter_test/flutter_test.dart';
import 'package:soundcloud_clone/features/premium/data/repositories/mock_subscription_repository.dart';

void main() {
  late MockSubscriptionRepository repo;

  setUp(() {
    repo = MockSubscriptionRepository();
  });

  test('returns FREE initially', () async {
    final result = await repo.getMySubscription();
    expect(result.subscriptionType, 'FREE');
  });

  test('createCheckout returns URL', () async {
    final url = await repo.createCheckout('PRO');
    expect(url, isNotEmpty);
  });

  test('getPlans returns list of plans', () async {
    final plans = await repo.getPlans();
    expect(plans.isNotEmpty, true);
  });

  test('cancel, resume, changePlan, and portal update mock state', () async {
    await repo.createCheckout('PRO');
    await repo.cancelSubscription();
    expect((await repo.getMySubscription()).cancelAtPeriodEnd, isTrue);

    await repo.resumeSubscription();
    expect((await repo.getMySubscription()).cancelAtPeriodEnd, isFalse);

    await repo.changePlan('FREE');
    final free = await repo.getMySubscription();
    expect(free.subscriptionType, 'FREE');
    expect(free.remainingUploads, 3);

    expect(await repo.openPortal(), contains('mock-portal'));
  });
}
