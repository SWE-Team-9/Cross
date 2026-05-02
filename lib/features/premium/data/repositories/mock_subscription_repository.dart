import '../../domain/entities/subscription.dart';
import '../../domain/entities/plan.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  Subscription _current = Subscription(
    subscriptionType: 'FREE',
    uploadLimit: 3,
    uploadedTracks: 3,
    remainingUploads: 0,
  );

  @override
  Future<Subscription> getMySubscription() async {
    return _current;
  }

  @override
  Future<String> createCheckout(String plan) async {
    await Future.delayed(const Duration(seconds: 1));

    // simulate success checkout → upgrade immediately
    if (plan == 'PRO') {
      _current = const Subscription(
        subscriptionType: 'PRO',
        uploadLimit: 1000,
        uploadedTracks: 2,
        remainingUploads: 998,
      );
    }

    return "https://mock-checkout-success";
  }

  @override
  Future<void> cancelSubscription() async {
    _current = Subscription(
      subscriptionType: _current.subscriptionType,
      uploadLimit: _current.uploadLimit,
      uploadedTracks: _current.uploadedTracks,
      remainingUploads: _current.remainingUploads,
      cancelAtPeriodEnd: true,
    );
  }

  @override
  Future<void> resumeSubscription() async {
    _current = Subscription(
      subscriptionType: _current.subscriptionType,
      uploadLimit: _current.uploadLimit,
      uploadedTracks: _current.uploadedTracks,
      remainingUploads: _current.remainingUploads,
      cancelAtPeriodEnd: false,
    );
  }

  @override
  Future<void> changePlan(String plan) async {
    _current = Subscription(
      subscriptionType: plan,
      uploadLimit: plan == 'FREE' ? 3 : 999,
      uploadedTracks: 0,
      remainingUploads: plan == 'FREE' ? 3 : 999,
      cancelAtPeriodEnd: false,
    );
  }

  @override
  Future<String> openPortal() async {
    return 'https://mock-portal.example.com';
  }

  @override
  Future<List<Plan>> getPlans() async {
    return [
      const Plan(
        code: 'FREE',
        name: 'Free',
        price: 0,
        description: 'Basic plan with limited uploads',
        interval: 'month',
      ),
      const Plan(
        code: 'PRO',
        name: 'Pro',
        price: 9.99,
        description: 'Unlimited uploads and premium features',
        interval: 'month',
      ),
    ];
  }
}
