import '../../domain/entities/subscription.dart';
import '../../domain/repositories/subscription_repository.dart';

class MockSubscriptionRepository implements SubscriptionRepository {
  Subscription _current = const Subscription(
    subscriptionType: 'FREE',
    uploadLimit: 3,
    uploadedTracks: 3,
    remainingUploads: 0,
  );

  @override
  Future<Subscription> getMySubscription() async {
    return _current;
  }

  Future<Subscription> subscribe(String plan) async {
    await Future.delayed(const Duration(seconds: 1)); // simulate network

    if (plan == 'PRO') {
      _current = const Subscription(
        subscriptionType: 'PRO',
        uploadLimit: 1000,
        uploadedTracks: 2,
        remainingUploads: 998,
      );
    }

    return _current;
  }
}
