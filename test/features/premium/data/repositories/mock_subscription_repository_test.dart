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

  test('subscribe upgrades to PRO', () async {
    final result = await repo.subscribe('PRO');
    expect(result.subscriptionType, 'PRO');
  });
}
