import '../../domain/entities/subscription.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/subscription_repository.dart';

/// Minimal implementation returning safe defaults to avoid breaking other code.
class SubscriptionRepositoryImpl implements SubscriptionRepository {
  // Keep a single optional parameter to match callers/tests that pass a DioClient.
  SubscriptionRepositoryImpl([dynamic _dioClient]);

  @override
  Future<Subscription> getMySubscription() async {
    return const Subscription();
  }

  @override
  Future<String> createCheckout(String plan) async {
    return 'https://mock-checkout';
  }

  @override
  Future<List<Plan>> getPlans() async {
    return [
      const Plan(code: 'FREE', name: 'Free', price: 0, description: '', interval: 'month'),
    ];
  }

  @override
  Future<void> cancelSubscription() async {}

  @override
  Future<void> resumeSubscription() async {}

  @override
  Future<void> changePlan(String plan) async {}

  @override
  Future<String> openPortal() async => 'https://mock-portal';
}
