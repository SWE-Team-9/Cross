import '../../domain/entities/subscription.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  Subscription _current = const Subscription();

  @override
  Future<Subscription> getMySubscription() async => _current;

  @override
  Future<String> createCheckout(String plan) async {
    // Immediately simulate success
    if (plan == 'PRO') {
      _current = const Subscription(subscriptionType: 'PRO', uploadLimit: 999, uploadedTracks: 0, remainingUploads: 999);
    }
    return 'https://mock-checkout-success';
  }

  @override
  Future<void> cancelSubscription() async {
    _current = Subscription(subscriptionType: _current.subscriptionType, uploadLimit: _current.uploadLimit, uploadedTracks: _current.uploadedTracks, remainingUploads: _current.remainingUploads, cancelAtPeriodEnd: true);
  }

  @override
  Future<void> resumeSubscription() async {
    _current = Subscription(subscriptionType: _current.subscriptionType, uploadLimit: _current.uploadLimit, uploadedTracks: _current.uploadedTracks, remainingUploads: _current.remainingUploads, cancelAtPeriodEnd: false);
  }

  @override
  Future<void> changePlan(String plan) async {
    _current = Subscription(subscriptionType: plan, uploadLimit: plan == 'FREE' ? 3 : 999, uploadedTracks: 0, remainingUploads: plan == 'FREE' ? 3 : 999);
  }

  @override
  Future<String> openPortal() async => 'https://mock-portal.example.com';

  @override
  Future<List<Plan>> getPlans() async => [
        const Plan(code: 'FREE', name: 'Free', price: 0, description: '', interval: 'month'),
      ];
}
